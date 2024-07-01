package main

import (
	"Memento/server/model"
	"Memento/server/service"
	"github.com/labstack/echo/v4"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"net/http"
)

func main() {

	db, err := gorm.Open(sqlite.Open("test.db"), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}

	// Migrate the schema
	db.AutoMigrate(&model.Post{})
	db.AutoMigrate(&model.User{})
	e := echo.New()

	// post api
	e.GET("/api/post/get/:id", service.HandlePostGet)
	e.POST("/api/post/create", service.HandlePostCreate)
	e.POST("/api/post/edit", service.HandlePostEdit)
	e.DELETE("/api/post/delete", service.HandlePostDelete)

	// user api
	e.GET("/api/user/get", service.HandleUserGet)
	e.GET("/api/user/login", service.HandleUserLogin)
	e.GET("/api/user/changePwd", service.HandleUserChangePwd)
	e.POST("/api/user/create", service.HandleUserCreate)
	e.POST("/api/user/edit", service.HandleUserEdit)
	e.DELETE("/api/user/delete", service.HandleUserDelete)

	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello, World!")
	})

	e.Logger.Fatal(e.Start(":1323"))
}
