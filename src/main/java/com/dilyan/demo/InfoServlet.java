package com.dilyan.demo;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebServlet(urlPatterns = {"/health", "/version"})
public class InfoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        String body;
        if ("/health".equals(req.getServletPath())) {
            body = "{\"status\":\"UP\"}";
        } else {
            String version = System.getenv().getOrDefault("APP_VERSION", "dev");
            String host = System.getenv().getOrDefault("HOSTNAME", "unknown");
            body = "{\"version\":\"" + version + "\",\"host\":\"" + host + "\"}";
        }
        resp.getWriter().write(body);
    }
}
