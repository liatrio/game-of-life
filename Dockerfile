FROM tomcat:9.0-alpine

COPY gameoflife-web/target/gameoflife.war /usr/local/tomcat/webapps/gameoflife.war
