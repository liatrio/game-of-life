FROM tomcat:9.0-alpine

COPY target/gameoflife-web.war /usr/local/tomcat/webapps/gameoflife-web.war
