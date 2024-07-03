package memento

import (
	"Memento/memento/model"
	"Memento/memento/utils"
	echoserver "github.com/dasjott/oauth2-echo-server"
	"github.com/go-oauth2/oauth2/v4/server"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"os"
	"path"
	"sync"
)

type MementoServer struct {
	DbConn *gorm.DB
	Config utils.MementoConfig
	lock   sync.Locker
}

var memento MementoServer

func Init() *MementoServer {
	data, err := os.ReadFile("./memento/configuration.yaml")
	if err != nil {
		log.Errorf("Error opening configuration file: %s\n", err.Error())
		return nil
	}
	err = yaml.Unmarshal(data, &memento.Config)
	if err != nil {
		log.Errorf("Error unmarshalling yaml file: %s\n", err.Error())
		return nil
	}

	memento.DbConn, err = gorm.Open(sqlite.Open(memento.Config.DbConfig.Database), &gorm.Config{
		TranslateError:                           true,
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		log.Errorf("Error establishing database connection: %s\n", err.Error())
		return nil
	}
	memento.DbConn.AutoMigrate(&model.User{})
	memento.DbConn.AutoMigrate(&model.Post{})
	memento.DbConn.AutoMigrate(&model.UserLike{})
	memento.DbConn.AutoMigrate(&model.UserPost{})
	memento.DbConn.AutoMigrate(&model.PostFile{})
	return &memento
}

func GetAvatarPath() string {
	return path.Join(memento.Config.FilePath, "avatar")
}

func GetPostPath() string {
	return path.Join(memento.Config.FilePath, "post")
}

func GetFilePath() string {
	return path.Join(memento.Config.FilePath, "file")
}

func GetConfig() *utils.MementoConfig {
	return &memento.Config
}

func GetDbConnection() *gorm.DB {
	return memento.DbConn
}

func Lock() {
	memento.lock.Lock()
}
func Unlock() {
	memento.lock.Unlock()
}

func ValidateToken(cfg *echoserver.Config, eServer *server.Server) echo.MiddlewareFunc {
	tokenKey := cfg.TokenKey
	if tokenKey == "" {
		tokenKey = echoserver.DefaultConfig.TokenKey
	}

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if cfg.Skipper != nil && cfg.Skipper(c) {
				return next(c)
			}
			ti, err := eServer.ValidationBearerToken(c.Request())
			if err != nil {
				return utils.RespondError(c, "invalid token")
			}

			c.Set(tokenKey, ti)
			return next(c)
		}
	}
}
