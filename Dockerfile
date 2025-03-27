# # Build stage
# FROM maven:3.8-openjdk-17 AS build
# COPY src /home/app/src

# COPY pom.xml /home/app
# RUN mvn -f /home/app/pom.xml clean package -DskipTests=true

# # Package stage
# FROM openjdk:21-ea-17-slim-buster
# # COPY --from=build /home/app/target/java-spring-boot-boilerplate-0.0.1-SNAPSHOT.jar /usr/local/lib/app.jar
# COPY --from=build /home/app/target/*.jar app.jar
# RUN chmod +x app.jar


# EXPOSE 8080
# # ENTRYPOINT ["java", "-jar", "/usr/local/lib/app.jar"]
# ENTRYPOINT ["java", "-jar", "app.jar"]

# Base image for Java application build
# FROM maven:3.8-openjdk-17 AS build
# WORKDIR /home/app
# COPY pom.xml .
# COPY src ./src
# RUN mvn clean package -DskipTests=true

# # Package stage
# FROM openjdk:21-ea-17-slim-buster
# WORKDIR /usr/local/lib

# # Install dependencies: PostgreSQL, Redis, Redis Commander, MailHog
# RUN apt-get update && apt-get install -y \
#     postgresql postgresql-contrib \
#     redis-server \
#     && rm -rf /var/lib/apt/lists/*

# # Set up PostgreSQL
# USER postgres
# RUN /etc/init.d/postgresql start && \
#     psql -tc "SELECT 1 FROM pg_roles WHERE rolname='postgres'" | grep -q 1 || psql -c "CREATE USER postgres WITH PASSWORD 'secret';" && \
#     psql -tc "SELECT 1 FROM pg_database WHERE datname='app_db'" | grep -q 1 || psql -c "CREATE DATABASE app_db;" && \
#     psql -c "ALTER ROLE postgres SUPERUSER;"

# # Switch back to root
# USER root

# # Configure Redis with password
# RUN echo "requirepass secret" >> /etc/redis/redis.conf

# # Copy built JAR file
# COPY --from=build /home/app/target/*.jar app.jar
# RUN chmod +x app.jar

# # Expose required ports
# EXPOSE 8080 5432 6379 8025 1025 6380

# # Start services and application
# CMD service postgresql start && \
#     redis-server /etc/redis/redis.conf & \
#     java -jar app.jar

# Build stage
FROM maven:3.8-openjdk-17 AS build
WORKDIR /app
COPY src ./src
COPY pom.xml ./

RUN mvn clean package -DskipTests=true

# Package stage
# FROM openjdk:21-ea-17-slim-buster
FROM ubuntu:22.04

WORKDIR /usr/local/lib

# Copy JAR from build stage
COPY --from=build /home/app/target/*.jar app.jar

# Install PostgreSQL client
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*

# Copy the wait-for-postgres script
COPY wait-for-postgres.sh /usr/local/bin/wait-for-postgres.sh
RUN chmod +x /usr/local/bin/wait-for-postgres.sh

EXPOSE 8080

# Start application only when PostgreSQL is ready
CMD ["/usr/local/bin/wait-for-postgres.sh"]
