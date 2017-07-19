FROM tomcat:9.0-alpine

RUN pwd
COPY gameoflife-web/target/gameoflife-web.war /usr/local/tomcat/webapps/gameoflife-web.war
