# Use official Tomcat image with JDK 17
FROM tomcat:10.1.10-jdk17

# Set working directory
WORKDIR /usr/local/tomcat

# Remove default ROOT webapp
RUN rm -rf webapps/ROOT

# Copy WAR built by Jenkins into ROOT.war
COPY ROOT.war webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Run Tomcat as non-root user
USER 1000:1000

# Optional healthcheck
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8080/ || exit 1

# Start Tomcat in foreground
CMD ["catalina.sh", "run"]
