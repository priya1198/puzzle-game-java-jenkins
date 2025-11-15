
# -------- Final Tomcat Image --------
FROM tomcat:10.1.10-jdk17

# Remove default ROOT
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copy WAR built by Jenkins (Jenkins copies target/app.war)
COPY target/app.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
