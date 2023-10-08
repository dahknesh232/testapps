# Use an official Node.js runtime as a parent image
FROM node:14

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy all your application code to the working directory
COPY . .

# Expose the port that your app will run on
EXPOSE 3100

# Define the command to run your application
CMD ["node", "app1.js"]
