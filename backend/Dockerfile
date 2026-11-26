FROM alpine:3.20
RUN apk add --no-cache python3 py3-psycopg2 \
  && addgroup -g 1001 -S appgroup \
  && adduser -u 1001 -S -D -H -G appgroup -s /sbin/nologin appuser
WORKDIR /app
COPY app.py .
RUN chown -R 1001:1001 /app
USER 1001:1001
EXPOSE 8080
CMD ["python3", "/app/app.py"]