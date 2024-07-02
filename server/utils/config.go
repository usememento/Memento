package utils

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
	PostPath string
	FilePath string
}

type MementoConfig struct {
	DbConfig      `yaml:"database"`
	ServiceConfig `yaml:"service"`
	ServerConfig  `yaml:"server"`
}
