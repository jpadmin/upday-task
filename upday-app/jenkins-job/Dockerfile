FROM mcr.microsoft.com/java/jre-headless:11-zulu-alpine

USER root

RUN adduser application --home /home/application/ --disabled-password --uid 1824

USER application

RUN wget -q -O /home/application/helloworld.jar https://upday-interview-test.s3-eu-west-1.amazonaws.com/helloworld.jar

WORKDIR /home/application/

ENTRYPOINT java -jar /home/application/helloworld.jar
