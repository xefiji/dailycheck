package dailycheck

type Option func(*config) error

type config struct {
	DB    database
	Reset bool
}

type database struct {
	Host     string
	Port     string
	Username string
	Password string
	Name     string
}

func WithDB(user, pass, host, port, name string) Option {
	return func(cfg *config) error {
		cfg.DB.Port = port
		cfg.DB.Username = user
		cfg.DB.Password = pass
		cfg.DB.Host = host
		cfg.DB.Name = name
		return nil
	}
}
