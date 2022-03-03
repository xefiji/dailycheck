package dailycheck

type Option func(*config) error

type config struct {
	DB   database
	Port string
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

func WithPort(port string) Option {
	return func(cfg *config) error {
		cfg.Port = port
		return nil
	}
}
