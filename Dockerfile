# -------- Final Tomcat Image --------
FROM tomcat:10.1.10-jdk17

# Remove default ROOT webapp
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copy WAR built by Jenkins into ROOT.war
# Make sure the WAR name matches the actual WAR generated
COPY target/puzzle-game-webapp-1.0.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
