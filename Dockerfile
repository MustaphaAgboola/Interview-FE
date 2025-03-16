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
ENV NODE_ENV production

# Add a non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy only necessary files from builder
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public 2>/dev/null || :

# Copy next.config.js if it exists
COPY --from=builder /app/next.config.js ./ 2>/dev/null || :

# Set appropriate permissions
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port 3000
EXPOSE 3000

# Start the application
CMD ["npm", "start"]