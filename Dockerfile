FROM registry.access.redhat.com/ubi8/openjdk-11:1.10 AS build

WORKDIR /home/jboss

COPY pom.xml ./
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean compile package -DskipTests

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.4 

ARG JAVA_PACKAGE=java-11-openjdk-headless
ARG RUN_JAVA_VERSION=1.3.8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'
# Install java, maven, and the run-java script
# Also set up permissions for user `1001`
RUN microdnf install curl ca-certificates ${JAVA_PACKAGE} \
    && microdnf update \
    && microdnf clean all \
    && mkdir /deployments \
    && chown 1001 /deployments \
    && chmod "g+rwX" /deployments \
    && chown 1001:root /deployments \
    && curl https://repo1.maven.org/maven2/io/fabric8/run-java-sh/${RUN_JAVA_VERSION}/run-java-sh-${RUN_JAVA_VERSION}-sh.sh -o /deployments/run-java.sh \
    && chown 1001 /deployments/run-java.sh \
    && chmod 540 /deployments/run-java.sh \
    && echo "securerandom.source=file:/dev/urandom" >> /etc/alternatives/jre/conf/security/java.security

COPY --from=build --chown=1001 /home/jboss/target/*.jar /deployments/

EXPOSE 8080
USER 1001

ENTRYPOINT [ "/deployments/run-java.sh" ]

