FROM golang:latest as builder

FROM scratch

WORKDIR /app

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY ./dist/dailycheck /app
COPY ./dist/build /app/web/build
COPY ./dist/public /app/web/public

EXPOSE 80

CMD ["/app/dailycheck"]