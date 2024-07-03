package main

import (
	"Memento/server"
	"Memento/server/service"
	"fmt"
	"github.com/labstack/echo/v4"
)

func main() {

	e := echo.New()
	server.Memento.Init()
	fmt.Println(server.Memento.Config.ServerConfig)
	// post api
	e.GET("/api/post/get", service.HandlePostGet)
	e.POST("/api/post/create", service.HandlePostCreate)
	e.POST("/api/post/edit", service.HandlePostEdit)
	e.DELETE("/api/post/delete", service.HandlePostDelete)

	// user api
	e.GET("/api/user/getInfo", service.HandleUserGetInfo)
	e.GET("/api/user/getAvatar", service.HandleUserGetAvatar)
	e.POST("/api/user/login", service.HandleUserLogin)
	e.POST("/api/user/changePwd", service.HandleUserChangePwd)
	e.POST("/api/user/create", service.HandleUserCreate)
	e.POST("/api/user/edit", service.HandleUserEdit)
	e.DELETE("/api/user/delete", service.HandleUserDelete)

	e.Logger.Fatal(e.Start(":1323"))
}
