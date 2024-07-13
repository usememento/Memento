package utils

var (
	DefaultConfig = MementoConfig{
		DbConfig{
			Driver:   "sqlite",
			Database: "memento.db",
		},
		ServiceConfig{},
		ServerConfig{
			Name:           "Memento",
			Version:        "0.1.0",
			Port:           1323,
			BasePath:       "",
			EnableRegister: true,
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
	Name           string
	Version        string
	Port           uint16
	BasePath       string
	EnableRegister bool `yaml:"enable_register"`
}

type MementoConfig struct {
	DbConfig      `yaml:"database"`
	ServiceConfig `yaml:"service"`
	ServerConfig  `yaml:"server"`
}
