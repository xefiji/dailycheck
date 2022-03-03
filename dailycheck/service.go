package dailycheck

type service struct {
	repo *repository
}

func newService(repo *repository) *service {
	return &service{
		repo: repo,
	}
}

func (s *service) get(memberID string) (dayDatas, error) {
	return s.repo.get(memberID)
}

func (s *service) add(memberID string, day dayDatas) (dayDatas, error) {
	return s.repo.save(memberID, day)
}
