package dailycheck

type Option func(*config) error

type config struct {
	DB database
}

type database struct {
	Name string
}

func WithDB(name string) Option {
	return func(cfg *config) error {
		cfg.DB.Name = name
		return nil
	}
}
