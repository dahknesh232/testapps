# Use the official Keycloak image as the base image
FROM bitnami/keycloak:latest

# Set environment variables
ENV KEYCLOAK_HTTP_PORT=8080
ENV KEYCLOAK_CREATE_ADMIN_USER=true
ENV KEYCLOAK_ADMIN_USER=admin
ENV KEYCLOAK_ADMIN_PASSWORD=adminpw
ENV KEYCLOAK_DATABASE_NAME=keycloak
ENV KEYCLOAK_DATABASE_PASSWORD=mysecretpassword

# Expose the required port
EXPOSE 8080

