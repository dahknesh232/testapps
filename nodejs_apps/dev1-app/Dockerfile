# Use an official Node.js image as the base image
FROM node:14

RUN mkdir -p /app

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install the application dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

# Expose the port your application will listen on
EXPOSE 3100

# Define the command to run your application
RUN npm start
