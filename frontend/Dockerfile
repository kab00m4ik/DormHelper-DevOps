FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY default.conf /etc/nginx/conf.d/default.conf
RUN addgroup -g 1001 -S appgroup 2>/dev/null || true \
  && adduser -u 1001 -S -D -H -G appgroup -s /sbin/nologin appuser 2>/dev/null || true \
  && grep -v '^[[:space:]]*pid[[:space:]]' /etc/nginx/nginx.conf > /tmp/nginx.conf.tmp \
  && echo 'pid /tmp/nginx.pid;' | cat - /tmp/nginx.conf.tmp > /etc/nginx/nginx.conf \
  && rm -f /tmp/nginx.conf.tmp \
  && sed -i 's/user  nginx;/# user disabled/' /etc/nginx/nginx.conf \
  && mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp \
  && chown -R 1001:1001 /var/cache/nginx /var/run /var/log/nginx /usr/share/nginx/html /etc/nginx/conf.d /etc/nginx/nginx.conf /tmp
USER 1001:1001
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]