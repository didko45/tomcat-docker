# tomcat-docker

[![CI](https://github.com/didko45/tomcat-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/didko45/tomcat-docker/actions/workflows/ci.yml)

A Java web application on Apache Tomcat, packaged with a multi-stage Docker build and served behind an Apache HTTP Server reverse proxy with Docker Compose.

## Architecture

```
client ──:80──► web (Apache httpd 2.4) ──:8080──► app (Tomcat 10.1, JRE 17)
                 public                            internal only
```

- `app` is reachable only from the internal Compose network; `web` is the single entry point.
- `web` starts only after `app` reports healthy.

## Run

```bash
docker compose up -d --build
curl http://localhost/health    # {"status":"UP"}
curl http://localhost/version   # {"version":"0.3","host":"<container id>"}
docker compose down
```

## Design decisions

| Decision | Reason |
| --- | --- |
| Multi-stage build | Maven and the JDK stay in the build stage; only `ROOT.war` reaches the runtime image |
| JRE base instead of JDK | Runtime needs no compiler; image content size dropped from 227 MB to 125 MB (-45%) |
| Non-root user (UID 10001) | Tomcat can write only to `logs`, `temp`, `work` and `webapps`; `conf` and `lib` stay root-owned |
| `HEALTHCHECK` on `/health` | Docker and Compose know whether the app responds, not just whether the process runs |
| `-XX:MaxRAMPercentage=75.0` | JVM heap follows the container memory limit instead of a fixed `-Xmx` |
| Minimal `httpd.conf` | Only the modules needed for reverse proxying are loaded |
| Named volume for Tomcat logs | File logs survive container re-creation |

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `web` never starts | `docker compose ps` — is `app` healthy? Then `docker compose logs app` |
| `app` stays `unhealthy` | `docker inspect --format '{{json .State.Health}}' tomcat-docker-app-1` |
| Port 80 already in use | `sudo ss -tlnp` and look for `:80` |
| Shell scripts fail with `\r` errors | Files were saved with CRLF; `.gitattributes` enforces LF |
