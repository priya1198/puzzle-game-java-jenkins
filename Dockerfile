# -------- Final Tomcat Image --------
FROM tomcat:10.1.10-jdk17

# Set working directory
WORKDIR /usr/local/tomcat

# Remove default ROOT webapp
RUN rm -rf webapps/ROOT

# Copy WAR built by Jenkins into ROOT.war
# Make sure the WAR name matches the actual WAR generated
COPY target/puzzle-game-webapp-1.0.war webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Set user to Tomcat (non-root) for security
USER 1000:1000

# Optional: Healthcheck to monitor container
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

# Start Tomcat in foreground
CMD ["catalina.sh", "run"]
