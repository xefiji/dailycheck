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

func (r *repository) get(memberID string) (dayDatas, error) {
	if err := r.db.bucket(memberID); err != nil {
		return dayDatas{}, err
	}

	var result = newDay()

	err := r.db.connector.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(memberID))
		if b == nil {
			return fmt.Errorf("could not retrieve bucket %s", memberID)
		}

		if elt := b.Get([]byte(result.Day)); elt != nil {
			return json.Unmarshal(elt, &result)
		}

		return nil
	})

	return result, err
}
