package dailycheck

import (
	"encoding/json"
	"fmt"
	"time"

	bolt "go.etcd.io/bbolt"
)

type repository struct {
	db cnx
}

func newRepository(c cnx) *repository {
	return &repository{
		db: c,
	}
}

func (r *repository) save(memberID string, day dayDatas) (dayDatas, error) {
	if err := r.db.bucket(memberID); err != nil {
		return dayDatas{}, err
	}

	j, err := json.Marshal(day)
	if err != nil {
		return dayDatas{}, err
	}

	err = r.db.connector.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(memberID))
		if b == nil {
			return fmt.Errorf("could not retrieve bucket %s", memberID)
		}

		err := b.Put([]byte(day.Day), j)
		return err
	})

	return day, err
}

func (r *repository) get(memberID string, day time.Time) (dayDatas, error) {
	if err := r.db.bucket(memberID); err != nil {
		return dayDatas{}, err
	}

	var result = newDay(day)

	err := r.db.connector.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(memberID))
		if b == nil {
			return fmt.Errorf("could not retrieve bucket %s", memberID)
		}

		c := b.Cursor()

		for k, v := c.First(); k != nil; k, v = c.Next() {
			if string(k) == day.Format(dayFormatYMD) {
				return json.Unmarshal(v, &result)
			}
		}
		return nil
	})

	return result, err
}
