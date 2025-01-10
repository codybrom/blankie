FROM node:lts AS base
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Development dependencies installation for dev server
RUN npm install

# Copy source
COPY . .

# Development command
CMD ["npm", "run", "dev", "--", "--host"]