
FROM nginx:alpine

ARG APP_MODE=stable

COPY index.html /usr/share/nginx/html/index.html

# Deliberately break Nginx only for the faulty release.
RUN if [ "$APP_MODE" = "faulty" ]; then \
      printf 'invalid_nginx_directive;\n' > /etc/nginx/conf.d/default.conf; \
    fi

EXPOSE 80
