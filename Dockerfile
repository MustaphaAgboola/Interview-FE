# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
# Set NODE_ENV
ENV NODE_ENV=production

# Add a non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only necessary files from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next

# Create public directory
RUN mkdir -p ./public

# Handle optional files with shell script
RUN if [ -d /builder/app/public ]; then cp -r /builder/app/public/* ./public/; fi && \
    if [ -f /builder/app/next.config.js ]; then cp /builder/app/next.config.js ./; fi || true

# Set appropriate permissions
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port 3000
EXPOSE 3000

# Start the application
CMD ["npm", "start"]