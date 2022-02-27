package dailycheck

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func dayHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"day":       time.Now().Format("2006-01-02"),
			"sleep":     1,
			"energy":    2,
			"intellect": 3,
			"anxiety":   4,
			"family":    5,
			"social":    4,
			"work":      3,
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
