FROM nginxinc/nginx-unprivileged:stable-alpine

USER root
RUN apk upgrade --no-cache

COPY index.html /usr/share/nginx/html/index.html

USER 101
EXPOSE 8080
