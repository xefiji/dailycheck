package dailycheck

type service struct {
	repo *repository
}

func newService(repo *repository) *service {
	return &service{
		repo: repo,
	}
}

func (s *service) get(day string) (dayDatas, error) {
	return s.repo.get(day)
}

func (s *service) add(day dayDatas) (dayDatas, error) {
	return s.repo.save(day)
}
