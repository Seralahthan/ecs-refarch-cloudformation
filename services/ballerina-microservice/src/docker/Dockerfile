# Auto Generated Dockerfile

FROM ballerina/ballerina-runtime:0.990.2
LABEL maintainer="dev@ballerina.io"

COPY utility.balx /home/ballerina 

COPY mysql-connector-java-8.0.13.jar /ballerina/runtime/bre/lib
EXPOSE  8280
CMD ballerina run  utility.balx
