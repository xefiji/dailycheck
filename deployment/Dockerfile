FROM golang:latest as builder

FROM scratch

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY ./dist/dailycheck /app/dailycheck
COPY ./dist/build /app/build
COPY ./dist/public /app/public

EXPOSE 8080

CMD ["/app/dailycheck"]