package server

import (
	"Memento/server/model"
	"Memento/server/utils"
	"fmt"
	"gopkg.in/yaml.v3"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"os"
	"sync"
)

type MementoServer struct {
	DbConn *gorm.DB
	Config utils.MementoConfig
	lock   sync.Locker
}

var Memento MementoServer

func (server *MementoServer) Init() {
	data, err := os.ReadFile("./server/configuration.yaml")
	if err != nil {
		fmt.Println("Error opening configuration file", err)
		return
	}
	err = yaml.Unmarshal(data, &server.Config)
	if err != nil {
		fmt.Println("Error unmarshalling yaml file", err)
		return
	}

	server.DbConn, err = gorm.Open(sqlite.Open("test.db"), &gorm.Config{
		TranslateError:                           true,
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		fmt.Println("Error opening database connection:", err)
		return
	}
	server.DbConn.AutoMigrate(&model.User{})
	server.DbConn.AutoMigrate(&model.Post{})
	server.DbConn.AutoMigrate(&model.UserLike{})
	server.DbConn.AutoMigrate(&model.UserPost{})
}
