FROM tomcat:9.0-alpine

COPY target/gameoflife.war /usr/local/tomcat/webapps/gameoflife.war
