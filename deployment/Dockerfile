FROM golang:latest as builder

FROM scratch

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY ./dist/dailycheck /
COPY ./dist/build /web/build
COPY ./dist/public /web/public

EXPOSE 8080

CMD ["/dailycheck"]