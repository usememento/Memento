package utils

var (
	DefaultConfig = MementoConfig{
		DbConfig{
			Driver:   "sqlite",
			Database: "memento.db",
		},
		ServerConfig{
			Name:           "Memento",
			Version:        "0.1.0",
			Port:           1323,
			BasePath:       "",
			EnableRegister: true,
			SiteName:       "Memento",
			Description:    "Memento is a self-hosted note-taking service.",
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

type ServerConfig struct {
	Name           string
	Version        string
	Port           uint16
	BasePath       string
	EnableRegister bool `yaml:"enable_register"`
	SiteName       string
	Description    string
	IconVersion    uint
}

type MementoConfig struct {
	DbConfig     `yaml:"database"`
	ServerConfig `yaml:"server"`
}
