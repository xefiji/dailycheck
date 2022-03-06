FROM golang:latest as builder

FROM scratch

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

WORKDIR /app
COPY ./dist/dailycheck /app
COPY ./dist/build /app/web/build
COPY ./dist/public /app/web/public

WORKDIR /app/db
WORKDIR /app

EXPOSE 80

CMD ["/app/dailycheck"]