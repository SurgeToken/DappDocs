FROM node:alpine
LABEL description="A demo Dockerfile for build Docsify."
WORKDIR /docs
COPY . .
RUN npm install -g docsify-cli@latest
EXPOSE 3000/tcp
ENTRYPOINT docsify serve .
