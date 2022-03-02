package dailycheck

import (
	bolt "go.etcd.io/bbolt"
)

type rw interface {
	Update(fn func(*bolt.Tx) error) error
	View(fn func(*bolt.Tx) error) error
}

type cnx struct {
	connector rw
}

func getDB(name string) (cnx, error) {
	b, err := bolt.Open(name, 0600, nil)
	if err != nil {
		return cnx{}, err
	}

	return cnx{
		connector: b,
	}, nil
}

func (cnx *cnx) bucket(name string) error {
	return cnx.connector.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(name))
		return err
	})
}
