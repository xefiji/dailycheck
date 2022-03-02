package dailycheck

import (
	"encoding/json"
	"fmt"

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

func (r *repository) save(day dayDatas) (dayDatas, error) {
	if err := r.db.bucket("MyBucket"); err != nil {
		return dayDatas{}, err
	}

	j, err := json.Marshal(day)
	if err != nil {
		return dayDatas{}, err
	}

	err = r.db.connector.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("MyBucket"))
		if b == nil {
			return fmt.Errorf("could not retrieve bucket %s", "MyBucket")
		}

		err := b.Put([]byte(day.Day), j)
		return err
	})

	return day, err
}

func (r *repository) get(day string) (dayDatas, error) {
	if err := r.db.bucket("MyBucket"); err != nil {
		return dayDatas{}, err
	}

	var result = dayDatas{}

	err := r.db.connector.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("MyBucket"))
		if b == nil {
			return fmt.Errorf("could not retrieve bucket %s", "MyBucket")
		}

		res := b.Get([]byte(day))
		return json.Unmarshal(res, &result)
	})

	return result, err
}