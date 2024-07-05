package main

import (
	"Memento/memento"
	"Memento/memento/service"
	"fmt"
	echoserver "github.com/dasjott/oauth2-echo-server"
	"github.com/go-oauth2/oauth2/v4/manage"
	"github.com/go-oauth2/oauth2/v4/models"
	"github.com/go-oauth2/oauth2/v4/server"
	"github.com/go-oauth2/oauth2/v4/store"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

var AuthServer *server.Server

func main() {
	mServer := memento.Init()
	fmt.Println(mServer.Config.ServerConfig)
	manager := manage.NewDefaultManager()

	// token store
	manager.MustTokenStorage(store.NewFileTokenStore("data.db"))

	// client store
	clientStore := store.NewClientStore()
	clientStore.Set("000000", &models.Client{
		ID:     "000000",
		Secret: "999999",
		Domain: "http://localhost",
	})
	manager.MapClientStorage(clientStore)
	// Initialize the oauth2 service
	eServer := echoserver.InitServer(manager)
	echoserver.SetAllowGetAccessRequest(true)
	echoserver.SetClientAuthorizedHandler(memento.AllowAuthorizedHandler)
	echoserver.SetClientInfoHandler(server.ClientFormHandler)
	echoserver.SetPasswordAuthorizationHandler(service.PasswordAuthorizationHandler)
	e := echo.New()
	// Middleware
	e.Use(middleware.Logger())
	e.POST("/login", service.HandleLogin)
	e.POST("/create", service.HandleUserCreate)
	api := e.Group("/api")
	{
		api.Use(memento.TokenValidator(&echoserver.DefaultConfig, eServer))
		postApi := api.Group("/post")
		{
			postApi.GET("/get", service.HandlePostGet)
			postApi.GET("/userPosts", service.HandleGetUserPosts)
			postApi.POST("/create", service.HandlePostCreate)
			postApi.POST("/edit", service.HandlePostEdit)
			postApi.DELETE("/delete", service.HandlePostDelete)
			postApi.POST("/like", service.HandlePostLike)
			postApi.POST("/unlike", service.HandlePostCancelLike)
			postApi.POST("/taggedPosts", service.HandleGetTaggedPost)
		}
		userApi := api.Group("/user")
		{
			userApi.GET("/get", service.HandleUserGet)
			userApi.POST("/changePwd", service.HandleUserChangePwd)
			userApi.POST("/edit", service.HandleUserEdit)
			userApi.DELETE("/delete", service.HandleUserDelete)
			userApi.GET("/heatmap", service.HandleUserHeatMap)
			userApi.POST("/follow", service.HandleUserFollow)
			userApi.POST("/unfollow", service.HandleUserUnfollow)
		}
		fileApi := api.Group("/file")
		{
			fileApi.GET("/download", service.HandleFileDownload)
			fileApi.POST("/upload", service.HandleFileUpload)
			fileApi.DELETE("/delete", service.HandleFileDelete)
		}
		commentApi := api.Group("/comment")
		{
			commentApi.POST("/create", service.HandleCommentCreate)
			commentApi.POST("/edit", service.HandleCommentEdit)
			commentApi.DELETE("/delete", service.HandleCommentDelete)
			commentApi.POST("/like", service.HandleCommentLike)
			commentApi.POST("/unlike", service.HandleCommentCancelLike)
			commentApi.GET("/postComments", service.HandleGetPostComments)
		}
	}
	e.Logger.Fatal(e.Start(fmt.Sprintf(":%d", mServer.Config.ServerConfig.Port)))
}
