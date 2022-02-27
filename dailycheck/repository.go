package dailycheck

import (
	"github.com/rs/zerolog/log"
	bolt "go.etcd.io/bbolt"
)

type repository struct {
}

func newRepository() *repository {
	return &repository{}
}

func (r *repository) save(day dayDatas) error {
	db, err := getDB()
	if err != nil {
		log.Error().Err(err).Msg("could not connect to database")
		return err
	}
	defer db.Close()

	return db.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte("MyBucket"))
		if err != nil {
			return err
		}
		err = b.Put([]byte(day.Day), []byte("42"))
		return err
	})
}

func (r *repository) get(day string) error {
	db, err := getDB()
	if err != nil {
		log.Error().Err(err).Msg("could not connect to database")
		return err
	}
	defer db.Close()

	return db.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte("MyBucket"))
		if err != nil {
			return err
		}

		res := b.Get([]byte(day))
		log.Info().Str("day", string(res)).Msg("result")
		return nil
	})
}
