# =============================================================================
# TeamSync Sample Application - WOPI Host & Demo UI
# =============================================================================

FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (using npm install for flexibility with package.json updates)
RUN npm install --only=production

# Copy application files
COPY . .

# Expose port
EXPOSE 8080

# Start the application
CMD ["node", "server.js"]
