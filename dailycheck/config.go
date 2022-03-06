package dailycheck

type Option func(*config) error

type config struct {
	DB   database
	Port string
	API  string
}

type database struct {
	Path string
}

func WithDB(path string) Option {
	return func(cfg *config) error {
		cfg.DB.Path = path
		return nil
	}
}

func WithPort(port string) Option {
	return func(cfg *config) error {
		cfg.Port = port
		return nil
	}
}

func WithAPI(url string) Option {
	return func(cfg *config) error {
		cfg.API = url
		return nil
	}
}
