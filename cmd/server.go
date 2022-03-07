package main

import (
	"os"

	"github.com/joho/godotenv"
	"github.com/rs/zerolog/log"
	"github.com/xefiji/dailycheck/dailycheck"
)

func init() {
	if err := godotenv.Load(); err != nil {
		log.Warn().Msg("no env file loaded")
	}
}

func main() {
	if err := run(); err != nil {
		os.Exit(1)
	}
}

func run() error {
	return dailycheck.Listen(
		dailycheck.WithDB(env("DB", "db/dailycheck.db")),
		dailycheck.WithPort(env("PORT", "443")),
		dailycheck.WithAPI(env("API_URL", "http://localhost/")),
	)
}

func env(name, fallback string) string {
	if val, ok := os.LookupEnv(name); ok {
		return val
	}
	return fallback
}
