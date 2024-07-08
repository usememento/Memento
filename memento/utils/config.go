package utils

var (
	DefaultConfig = MementoConfig{
		DbConfig{
			User:     "root",
			Password: "123456",
			Host:     "127.0.0.1",
			Port:     1234,
			Driver:   "sqlite",
			Database: "memento.db",
		},
		ServiceConfig{},
		ServerConfig{
			Name:     "Memento",
			Version:  "0.1.0",
			Port:     1323,
			FilePath: "",
		},
	}
)

type DbConfig struct {
	User     string
	Password string
	Host     string
	Port     uint16
	Driver   string
	Database string
}

type ServiceConfig struct {
}

type ServerConfig struct {
	Name     string
	Version  string
	Port     uint16
	FilePath string
}

type MementoConfig struct {
	DbConfig      `yaml:"database"`
	ServiceConfig `yaml:"service"`
	ServerConfig  `yaml:"server"`
}
