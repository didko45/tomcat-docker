# ---- Stage 1: build the WAR with Maven ----
FROM maven:3.9-eclipse-temurin-26 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B package

# ---- Stage 2: runtime on Tomcat (JRE only) ----
FROM tomcat:10.1-jre17

# curl for the health check; non-root user with write access only where Tomcat needs it
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/local/tomcat/webapps/* /usr/local/tomcat/webapps.dist \
 && groupadd --system --gid 10001 tomcat \
 && useradd --system --uid 10001 --gid tomcat --home-dir /usr/local/tomcat --shell /usr/sbin/nologin tomcat \
 && chown -R tomcat:tomcat /usr/local/tomcat/logs /usr/local/tomcat/temp /usr/local/tomcat/work /usr/local/tomcat/webapps

COPY --from=build --chown=tomcat:tomcat /src/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war

# JVM sizes the heap from the container's memory limit
ENV CATALINA_OPTS="-XX:MaxRAMPercentage=75.0"

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
  CMD ["curl", "-fsS", "http://localhost:8080/health"]
