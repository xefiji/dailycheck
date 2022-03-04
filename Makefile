build: elm-build 
	go build -o deployment/dist/dailycheck cmd/server.go

build-linux: elm-build
	GOOS=linux go build -o deployment/dist/dailycheck cmd/server.go
	@cp -R web/build deployment/dist/
	@cp -R web/public deployment/dist/

run: build
	deployment/dist/dailycheck

elm-build:
	elm make web/src/Checkout.elm  --output web/build/dailycheck.js

dist: build-linux
	@if [ -z "$$VERSION" ]; then \
	echo "VERSION must be set"; \
	exit 2; \
	fi; \
	tag=$$(echo $$VERSION | sed -n "s/refs\/tags\///p"); \
	if [ $$tag ]; then \
		VERSION=$$tag; \
	else \
		echo "Only tag can be pushed to registry"; \
		exit 0; \
	fi; \
	docker build -t xefiji/dailycheck deployment; \
	docker tag xefiji/dailycheck xefiji/dailycheck:$$VERSION; \

# docker push xefiji/dailycheck:$$VERSION;