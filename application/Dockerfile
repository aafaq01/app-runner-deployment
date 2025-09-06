FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY src/ ./src/

RUN chown -R node:node /app
USER node

EXPOSE 8080

CMD ["npm", "start"]