# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:17-jdk-jammy

# Add a volume pointing to /tmp
VOLUME /tmp

# Make port 8761 available to the world outside this container
EXPOSE 8761

# The application's JAR file
ARG JAR_FILE=./build/libs/eureka-server-*.jar

# Add the application's JAR to the container
ADD ${JAR_FILE} app.jar

# Run the JAR file
ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/app.jar"]
