package dailycheck

import "time"

const (
	dayFormatYMD      = "2006-01-02"
	dayFormatReadable = "Monday, January 2 2006"
)

type service struct {
	repo *repository
}

func newService(repo *repository) *service {
	return &service{
		repo: repo,
	}
}

func (s *service) get(memberID string, day time.Time) (dayDatas, error) {
	d, err := s.repo.get(memberID, day)
	if err != nil {
		return d, err
	}

	d.setReadable()
	return d, nil
}

func (s *service) add(memberID string, day dayDatas) (dayDatas, error) {
	d, err := s.repo.save(memberID, day)
	if err != nil {
		return d, err
	}
	d.setReadable()
	return d, nil
}
