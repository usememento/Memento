package memento

import (
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"fmt"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/blevesearch/bleve/v2"
	"github.com/labstack/gommon/log"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type Server struct {
	DbConn    *gorm.DB
	Config    utils.MementoConfig
	lock      sync.Locker
	PostIndex bleve.Index
}

const (
	PageSize       = 20
	ConfigFileName = "config.yaml"
)

var memento Server

func WriteConfig() error {
	f, err := os.Create(path.Join(memento.Config.BasePath, ConfigFileName))
	if err != nil {
		log.Errorf("Error creating configuration file: %s\n", err.Error())
		return err
	}
	data, err := yaml.Marshal(memento.Config)
	if err != nil {
		log.Errorf("Error marshalling configuration: %s\n", err.Error())
		return err
	}
	_, err = f.Write(data)
	if err != nil {
		log.Errorf("Error writing configuration to file: %s\n", err.Error())
		return err
	}
	return nil
}
func initConfig() error {
	home, err := os.UserHomeDir()
	if err != nil {
		log.Errorf("Error getting home directory: %s\n", err.Error())
		return err
	}
	data, err := os.ReadFile(filepath.Join(home, ".memento", ConfigFileName))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			memento.Config = utils.DefaultConfig
			memento.Config.BasePath = filepath.Join(home, ".memento")
			if err = os.MkdirAll(GetBasePath(), 0777); err != nil {
				log.Errorf("Error creating base folder: %s\n", err.Error())
				return err
			}
			f, err := os.Create(path.Join(memento.Config.BasePath, ConfigFileName))
			if err != nil {
				log.Errorf("Error creating configuration file: %s\n", err.Error())
				return err
			}
			data, err := yaml.Marshal(memento.Config)
			if err != nil {
				log.Errorf("Error marshalling configuration: %s\n", err.Error())
				return err
			}
			_, err = f.Write(data)
			if err != nil {
				log.Errorf("Error writing configuration to file: %s\n", err.Error())
				return err
			}
		} else {
			log.Errorf("Error opening configuration file: %s\n", err.Error())
			return err
		}
	} else {
		err = yaml.Unmarshal(data, &memento.Config)
		if err != nil {
			log.Errorf("Error unmarshalling yaml file: %s\n", err.Error())
			return err
		}
	}
	return nil
}
func initDbConnection() error {
	db, err := gorm.Open(sqlite.Open(path.Join(GetBasePath(), GetConfig().DbConfig.Database)), &gorm.Config{
		TranslateError:                           true,
		DisableForeignKeyConstraintWhenMigrating: true,
		DisableNestedTransaction:                 true,
		//SkipDefaultTransaction:                   true,
	})
	if err != nil {
		log.Errorf("Error establishing database connection: %s\n", err.Error())
		return err
	}
	memento.DbConn = db
	return nil
}
func initFolder() error {
	if err := os.MkdirAll(GetUploadPath(), 0777); err != nil {
		log.Errorf("Error creating upload file folder: %s\n", err.Error())
		return err
	}
	if err := os.MkdirAll(GetPostPath(), 0777); err != nil {
		log.Errorf("Error creating post folder: %s\n", err.Error())
		return err
	}
	if err := os.MkdirAll(GetAvatarPath(), 0777); err != nil {
		log.Errorf("Error creating avatar folder: %s\n", err.Error())
		return err
	}
	return nil
}

func initSearchEngine() error {
	idx, err := bleve.Open(path.Join(GetBasePath(), "post_index.bleve"))
	if err != nil {
		mapping := bleve.NewIndexMapping()
		memento.PostIndex, err = bleve.New(path.Join(GetBasePath(), "post_index.bleve"), mapping)
		if err != nil {
			log.Errorf("Error creating post index: %s\n", err.Error())
			return err
		}
	}
	memento.PostIndex = idx
	return nil
}

func Init() error {
	err := initConfig()
	if err != nil {
		log.Errorf("Error reading config file: %s\n", err.Error())
		return err
	}
	err = initFolder()
	if err != nil {
		log.Errorf("Error initializing sub-folders: %s\n", err.Error())
		return err
	}
	err = initDbConnection()
	if err != nil {
		log.Errorf("Error establishing database connection: %s\n", err.Error())
		return err
	}
	err = initSearchEngine()
	if err != nil {
		log.Errorf("Error initializing bleve search: %s\n", err.Error())
		return err
	}
	return nil
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

func Db() *gorm.DB {
	return memento.DbConn
}

func Lock() {
	memento.lock.Lock()
}
func Unlock() {
	memento.lock.Unlock()
}
func IndexPost(post *model.Post) error {
	content, err := os.ReadFile(post.ContentUrl)
	if err != nil {
		return err
	}
	fmt.Println("indexing: ", string(content))
	return memento.PostIndex.Index(post.Username+strconv.Itoa(int(post.ID)), struct {
		ID      uint
		Content string
	}{
		ID:      post.ID,
		Content: string(content),
	})
}

func SearchPost(content string) (*bleve.SearchResult, error) {
	query := bleve.NewMatchQuery(content)
	query.SetField("Content")
	searchRequest := bleve.NewSearchRequest(query)
	searchRequest.Fields = append(searchRequest.Fields, "ID")
	searchResult, err := memento.PostIndex.Search(searchRequest)
	if err != nil {
		log.Fatal(err)
		return nil, err
	}
	return searchResult, nil
}
func isPublicPath(path string) bool {
	publicPaths := [...]string{
		"/api/post/get",
		"/api/file/download",
		"/api/comment/postComments",
		"/api/post/all",
		"/api/post/userPosts",
		"/api/post/tags",
		"/api/search",
		"/api/post/taggedPosts",
		"/api/post/likedPosts",
		"/api/user/avatar",
		"/api/user/get",
		"/api/user/follower",
		"/api/user/following",
		"/api/user/heatmap",
		"/api/user/login",
		"/api/user/refresh",
		"/api/user/create",
		"/api/comment/userComments",
		"/api/captcha/create",
		"/api/captcha/verify",
	}
	for _, p := range publicPaths {
		if strings.HasPrefix(path, p) {
			return true
		}
	}
	return false
}

func TokenValidator() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			accessToken := c.Request().Header.Get("Authorization")
			if accessToken == "" && isPublicPath(c.Request().URL.Path) {
				return next(c)
			}
			token, err := jwt.ParseWithClaims(accessToken, &model.JwtUserClaims{}, func(token *jwt.Token) (interface{}, error) {
				return []byte(memento.Config.AccessTokenSigningKey), nil
			})
			if err != nil || !token.Valid {
				return utils.RespondError(c, "Invalid JWT Token")
			}
			claims, ok := token.Claims.(*model.JwtUserClaims)
			if !ok {
				return utils.RespondError(c, "Unable to Parse JWT Claims")
			}
			c.Set("username", claims.Username)
			return next(c)
		}
	}
}
