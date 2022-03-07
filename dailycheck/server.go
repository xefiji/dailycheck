package dailycheck

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

// Listen is the entry point of the app.
func Listen(opts ...Option) error {
	cfg := new(config)
	for _, opt := range opts {
		if err := opt(cfg); err != nil {
			log.Error().Err(err).Msg("invalid configuration")
			return err
		}
	}
	db, err := getDB(cfg.DB.Path)
	if err != nil {
		log.Error().Err(err).Msg("could not connect to database")
		return err
	}
	service := newService(newRepository(db))

	router := gin.Default()
	router.LoadHTMLGlob("web/public/*.html")
	router.Static("/web/build", "./web/build")
	router.StaticFile("/web/public/images/favicon.ico", "./web/public/images/favicon.ico")

	router.GET("/", indexHandler(cfg.API))
	member := router.Group("member")
	{
		memberID := member.Group(":memberID")
		{
			memberID.GET("/day/:day", getDayHandler(service))
			memberID.POST("/day", postDayHandler(service))
		}
	}

	return serve(router, cfg.Port)
}

func serve(router http.Handler, port string) error {
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", port),
		Handler: router,
	}

	sink := make(chan error, 1)
	go func() {
		defer close(sink)
		sink <- srv.ListenAndServe()
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt)

	select {
	case <-quit:
		return shutdown(srv, "quit signaled")
	case err := <-sink:
		return err
	}
}

func shutdown(srv *http.Server, from string) error {
	ctx, cancel := context.WithTimeout(context.Background(), (20 * time.Second))
	defer cancel()
	log.Warn().Msg(fmt.Sprintf("shutting down from %s", from))
	return srv.Shutdown(ctx)
}
