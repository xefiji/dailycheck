package dailycheck

import (
	bolt "go.etcd.io/bbolt"
)

type DB interface {
	Update(fn func(*bolt.Tx) error) error
	View(fn func(*bolt.Tx) error) error
}

func getDB() (*bolt.DB, error) {
	db, err := bolt.Open("dailycheck.db", 0600, nil)
	if err != nil {
		return nil, err
	}
	return db, nil
}
