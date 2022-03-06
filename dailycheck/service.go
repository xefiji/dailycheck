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

func (s *service) get(memberID string) (dayDatas, error) {
	d, err := s.repo.get(memberID)
	if err != nil {
		return d, err
	}

	date, err := time.Parse(dayFormatYMD, d.Day)
	if err != nil {
		return d, err
	}

	d.DayReadable = date.Format(dayFormatReadable)
	return d, nil
}

func (s *service) add(memberID string, day dayDatas) (dayDatas, error) {
	return s.repo.save(memberID, day)
}
