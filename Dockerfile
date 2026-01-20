FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json package-lock.json tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY --from=build /app/build ./build
RUN printf '#!/bin/sh\nset -eu\n\nexec node /app/build/index.js\n' > /app/entrypoint.sh \
  && chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
