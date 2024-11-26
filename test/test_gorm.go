package main

import (
	"Memento/memento"
	"Memento/memento/model"
	"github.com/labstack/gommon/log"
)

func main() {
	err := memento.Init()
	if err != nil {
		log.Errorf("Error initializing memento server: %s\n", err.Error())
		return
	}
	_ = memento.Db().AutoMigrate(&model.Tag{})
	_ = memento.Db().AutoMigrate(&model.File{})
	_ = memento.Db().AutoMigrate(&model.Comment{})
	_ = memento.Db().AutoMigrate(&model.Post{})
	_ = memento.Db().AutoMigrate(&model.User{})
}
