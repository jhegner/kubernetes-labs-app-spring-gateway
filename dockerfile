# Stage 1: Build the application
FROM maven:3.9.10-amazoncorretto-21-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# ---- Stage 2: Runtime using Corretto 21 Alpine ----
FROM amazoncorretto:21-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080

# Allow dynamic profile via environment variable
ENV SPRING_PROFILES_ACTIVE=dev,prettylog
ENV SERVER_PORT=8080

# Run the Spring Boot app with profile support
ENTRYPOINT ["java", "-jar", "app.jar", "--spring.profiles.active=${SPRING_PROFILES_ACTIVE}", "--server.port=${SERVER_PORT}"]
