# Use Maven image for building the project
FROM maven:3.8.6 AS build

# Set the working directory
WORKDIR /app

# Copy the pom.xml to download dependencies
COPY pom.xml .

# Download the dependencies (this step is separated so we can cache the dependencies)
RUN mvn dependency:go-offline -B

# Copy the rest of the project files
COPY . .

# Skip tests and checkstyle plugin during build
RUN mvn clean package -DskipTests -Dcheckstyle.skip=true

# Use OpenJDK 17 for running the application
FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy the jar file from the build stage
COPY --from=build /app/target/spring-petclinic-*.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
