# Use an official Node.js runtime as a parent image
FROM node:14 as build-stage

# Set the working directory in the container
WORKDIR /app

# Copy the package.json and package-lock.json files to the container
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the app source code to the container
COPY ./src ./src

# Build the app
RUN npm run build

# Use an official Nginx runtime as a parent image
FROM nginx:stable-alpine

# Copy the built app to the container
COPY --from=build-stage /app/build /usr/share/nginx/html

# Copy the Nginx configuration to the container
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for Nginx
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
