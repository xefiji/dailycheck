build: elm-build 
	go build -o deployment/dist/dailycheck cmd/server.go

build-linux: 
	GOOS=linux go build -o deployment/dist/dailycheck cmd/server.go

run: build
	deployment/dist/dailycheck

elm-build:
	elm make web/src/Checkout.elm  --output web/build/dailycheck.js