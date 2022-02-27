package dailycheck

import "time"

type service struct {
	repo *repository
}

func newService(repo *repository) *service {
	return &service{
		repo: repo,
	}
}

func (s *service) get(day string) (dayDatas, error) {
	err := s.repo.get(day)
	if err != nil {
		return dayDatas{}, err
	}
	return dayDatas{
		Day: time.Now().Format("2006-01-02"),
	}, nil
}

func (s *service) add(day dayDatas) error {
	return s.repo.save(day)
}
