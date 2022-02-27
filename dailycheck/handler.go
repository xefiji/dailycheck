package dailycheck

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type dayDatas struct {
	Day       string `json:"day"`
	Sleep     int    `json:"sleep"`
	Energy    int    `json:"energy"`
	Intellect int    `json:"intellect"`
	Anxiety   int    `json:"anxiety"`
	Family    int    `json:"family"`
	Social    int    `json:"social"`
	Work      int    `json:"work"`
}

func getDayHandler(service *service) gin.HandlerFunc {
	return func(c *gin.Context) {
		today := time.Now().Format("2006-01-02")

		day, err := service.get(today)
		if err != nil {
			log.Error().Err(err).Caller().Str("day", today).Msg("failed to get day datas")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get day datas"})
			return
		}

		c.JSON(http.StatusOK, day)
	}
}

func postDayHandler(service *service) gin.HandlerFunc {
	return func(c *gin.Context) {
		var request = &dayDatas{}
		if err := c.ShouldBindJSON(&request); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if err := service.add(*request); err != nil {
			log.Error().Err(err).Caller().Interface("day", request).Msg("failed to add day datas")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to add day datas"})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"message": "ok",
		})
	}
}

func indexHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{
			"title": "Daily Check",
		})
	}
}
