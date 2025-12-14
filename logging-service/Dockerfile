# CONFIGURATION REQUIRED FOR DISCONNECTED ENV:
# Replace with your private Artifactory registry mirror for Node.js base image
# Example: FROM artifactory.yourcompany.local/docker/node:18-alpine
# Or configure Docker daemon to use registry mirror (recommended)
FROM node:18-alpine

WORKDIR /app

COPY package.json .
RUN npm install

COPY app.js .

EXPOSE 5000

CMD ["node", "app.js"]

