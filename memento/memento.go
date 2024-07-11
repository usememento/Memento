package memento

import (
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"fmt"
	"github.com/go-oauth2/oauth2/v4"
	"github.com/go-oauth2/oauth2/v4/server"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"net/http"
	"os"
	"path"
	"strings"
	"sync"
)

type MementoServer struct {
	DbConn *gorm.DB
	Config utils.MementoConfig
	lock   sync.Locker
}

const (
	PageSize       = 20
	ConfigFileName = "memento_cfg.yaml"
)

var JwtSecret = []byte("secret")
var memento MementoServer

func Init() (*MementoServer, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Errorf("Error getting home directory: %s\n", err.Error())
		return nil, err
	}
	data, err := os.ReadFile(path.Join(home, ".memento", ConfigFileName))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			memento.Config = utils.DefaultConfig
			memento.Config.BasePath = path.Join(home, ".memento")
			if err = os.MkdirAll(GetBasePath(), 0777); err != nil {
				log.Errorf("Error creating base folder: %s\n", err.Error())
				return nil, err
			}
			f, err := os.Create(path.Join(memento.Config.BasePath, ConfigFileName))
			if err != nil {
				log.Errorf("Error creating configuration file: %s\n", err.Error())
				return nil, err
			}
			data, err := yaml.Marshal(memento.Config)
			if err != nil {
				log.Errorf("Error marshalling configuration: %s\n", err.Error())
				return nil, err
			}
			_, err = f.Write(data)
			if err != nil {
				log.Errorf("Error writing configuration to file: %s\n", err.Error())
				return nil, err
			}
		} else {
			log.Errorf("Error opening configuration file: %s\n", err.Error())
			return nil, err
		}
	} else {
		err = yaml.Unmarshal(data, &memento.Config)
		if err != nil {
			log.Errorf("Error unmarshalling yaml file: %s\n", err.Error())
			return nil, err
		}
	}
	if err = os.MkdirAll(GetUploadPath(), 0777); err != nil {
		log.Errorf("Error creating upload file folder: %s\n", err.Error())
		return nil, err
	}
	if err = os.MkdirAll(GetPostPath(), 0777); err != nil {
		log.Errorf("Error creating post folder: %s\n", err.Error())
		return nil, err
	}
	if err = os.MkdirAll(GetAvatarPath(), 0777); err != nil {
		log.Errorf("Error creating avatar folder: %s\n", err.Error())
		return nil, err
	}
	memento.DbConn, err = gorm.Open(sqlite.Open(path.Join(GetBasePath(), GetConfig().DbConfig.Database)), &gorm.Config{
		TranslateError:                           true,
		DisableForeignKeyConstraintWhenMigrating: true,
		//SkipDefaultTransaction:                   true,
	})
	if err != nil {
		log.Errorf("Error establishing database connection: %s\n", err.Error())
		return nil, err
	}
	memento.DbConn.AutoMigrate(&model.Tag{})
	memento.DbConn.AutoMigrate(&model.File{})
	memento.DbConn.AutoMigrate(&model.Comment{})
	memento.DbConn.AutoMigrate(&model.Post{})
	memento.DbConn.AutoMigrate(&model.User{})
	//memento.DbConn.AutoMigrate(&model.PostTag{})
	return &memento, nil
}
func GetBasePath() string {
	return memento.Config.BasePath
}

func GetAvatarPath() string {
	return path.Join(memento.Config.BasePath, "avatar")
}

func GetPostPath() string {
	return path.Join(memento.Config.BasePath, "post")
}

func GetUploadPath() string {
	return path.Join(memento.Config.BasePath, "upload")
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

func isPublicPath(path string) bool {
	publicPaths := [...]string{"/api/post/get", "/api/file/download", "/api/comment/postComments", "/api/user/avatar"}
	for _, p := range publicPaths {
		if strings.HasPrefix(path, p) {
			return true
		}
	}
	return false
}

// TokenValidator middleware
func TokenValidator(eServer *server.Server) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			ti, err := eServer.ValidationBearerToken(c.Request())
			if err != nil {
				path := c.Request().URL.Path
				if isPublicPath(path) {
					c.Set("username", "")
					return next(c)
				}
				return c.JSON(http.StatusUnauthorized, map[string]string{
					"message": "invalid token",
				})
			}
			fmt.Printf("token validator: %s\n", ti.GetUserID())
			c.Set("token", ti)
			c.Set("username", ti.GetUserID())
			return next(c)
		}
	}
}

func AllowAuthorizedHandler(clientID string, grant oauth2.GrantType) (allowed bool, err error) {
	if grant.String() == "password" || grant.String() == "refresh_token" {
		return true, nil
	}
	return false, nil
}
func GetUser(out *model.User, username string) error {
	err := GetDbConnection().First(&out, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		log.Errorf(err.Error())
		return err
	}
	return nil
}

func GetPost(out *model.Post, postId string) error {
	if err := GetDbConnection().First(&out, "id=?", postId).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		log.Errorf(err.Error())
		return err
	}
	return nil
}

func GetFile(out *model.File, url string) error {
	err := GetDbConnection().First(&out, "content_url=?", url).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		log.Errorf(err.Error())
		return err
	}
	return nil
}

type Token struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	TokenType    string `json:"token_type"`
	Expiry       int64  `json:"expiry"`
}
