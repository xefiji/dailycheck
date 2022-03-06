package dailycheck

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type dayDatas struct {
	Day         string `json:"day"`
	DayReadable string `json:"day_readable"`
	Sleep       int    `json:"sleep"`
	Energy      int    `json:"energy"`
	Intellect   int    `json:"intellect"`
	Serenity    int    `json:"serenity"`
	Family      int    `json:"family"`
	Social      int    `json:"social"`
	Work        int    `json:"work"`
}

func (d *dayDatas) setReadable() {
	dt, err := time.Parse(dayFormatYMD, d.Day)
	if err != nil {
		log.Error().Err(err).Msg("failed setting day readable")
	} else {
		d.DayReadable = dt.Format(dayFormatReadable)
	}
}

func newDay(day time.Time) dayDatas {
	return dayDatas{
		Day:         day.Format(dayFormatYMD),
		DayReadable: day.Format(dayFormatReadable),
		Sleep:       0,
		Energy:      0,
		Intellect:   0,
		Serenity:    0,
		Family:      0,
		Social:      0,
		Work:        0,
	}
}

func getDayHandler(service *service) gin.HandlerFunc {
	return func(c *gin.Context) {
		memberID := c.Param("memberID")
		if memberID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or missing memberID param"})
			return
		}

		day, err := time.Parse(dayFormatYMD, c.Param("day"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid or missing day param"})
			return
		}

		dayDatas, err := service.get(memberID, day)
		if err != nil {
			log.Error().Str("memberID", memberID).Err(err).Caller().Interface("day", dayDatas).Msg("failed to get day datas")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to get day datas"})
			return
		}

		c.JSON(http.StatusOK, dayDatas)
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
			"date":   time.Now().Format(dayFormatReadable),
			"apiUrl": apiUrl,
		})
	}
}
