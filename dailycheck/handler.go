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

func newDay() dayDatas {
	return dayDatas{
		Day:       time.Now().Format("2006-01-02"),
		Sleep:     0,
		Energy:    0,
		Intellect: 0,
		Anxiety:   0,
		Family:    0,
		Social:    0,
		Work:      0,
	}
}

func getDayHandler(service *service) gin.HandlerFunc {
	return func(c *gin.Context) {
		memberID := c.Param("memberID")
		if memberID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing memberID"})
			return
		}

		day, err := service.get(memberID)
		if err != nil {
			log.Error().Str("memberID", memberID).Err(err).Caller().Interface("day", day).Msg("failed to get day datas")
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

		memberID := c.Param("memberID")
		if memberID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "missing memberID"})
			return
		}

		request.Day = time.Now().Format("2006-01-02")
		res, err := service.add(memberID, *request)
		if err != nil {
			log.Error().Err(err).Caller().Str("memberID", memberID).Interface("day", request).Msg("failed to add day datas")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to add day datas"})
			return
		}

		c.JSON(http.StatusCreated, res)
	}
}

func indexHandler(apiUrl string) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.html", gin.H{
			"title":  "Daily Check",
			"apiUrl": apiUrl,
		})
	}
}
