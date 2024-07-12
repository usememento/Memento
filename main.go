package main

import (
	"Memento/memento"
	"Memento/memento/service"
	"fmt"
	"github.com/go-oauth2/oauth2/v4"
	"github.com/go-oauth2/oauth2/v4/manage"
	"github.com/go-oauth2/oauth2/v4/models"
	"github.com/go-oauth2/oauth2/v4/server"
	"github.com/go-oauth2/oauth2/v4/store"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"
	"path"
)

var AuthServer *server.Server

func main() {
	mServer, err := memento.Init()
	if err != nil {
		log.Errorf("Error initializing memento server: %s\n", err.Error())
		return
	}
	fmt.Println(mServer.Config.ServerConfig)
	manager := manage.NewDefaultManager()

	// token store
	manager.MustTokenStorage(store.NewFileTokenStore(path.Join(memento.GetBasePath(), "token.db")))

	// client store
	clientStore := store.NewClientStore()
	clientStore.Set("000000", &models.Client{
		ID:     "000000",
		Secret: "999999",
		Domain: "http://localhost",
	})
	manager.MapClientStorage(clientStore)
	// Initialize the oauth2 service
	AuthServer = server.NewDefaultServer(manager)
	AuthServer.Config.AllowGetAccessRequest = true
	AuthServer.SetAllowedGrantType(oauth2.Refreshing, oauth2.PasswordCredentials)
	AuthServer.SetClientInfoHandler(server.ClientFormHandler)
	AuthServer.SetPasswordAuthorizationHandler(service.PasswordAuthorizationHandler)
	e := echo.New()
	// Middleware
	e.Use(middleware.Logger())
	service.ServeFrontend(e)
	e.POST("/api/user/refresh", func(c echo.Context) error {
		return service.HandleUserRefreshToken(c, AuthServer)
	})
	e.POST("/api/user/login", func(c echo.Context) error {
		return service.HandleUserLoginWrapper(c, AuthServer)
	})
	e.POST("/api/user/create", func(c echo.Context) error { return service.HandleUserCreateWrapper(c, AuthServer) })

	api := e.Group("/api")
	{
		api.Use(memento.TokenValidator(AuthServer))
		postApi := api.Group("/post")
		{
			postApi.GET("/all", service.HandleGetAllPosts)
			postApi.GET("/get", service.HandleGetPost)
			postApi.GET("/userPosts", service.HandleGetUserPosts)
			postApi.POST("/create", service.HandlePostCreate)
			postApi.POST("/edit", service.HandlePostEdit)
			postApi.DELETE("/delete/:id", service.HandlePostDelete)
			postApi.POST("/like", service.HandlePostLike)
			postApi.POST("/unlike", service.HandlePostCancelLike)
			postApi.GET("/taggedPosts", service.HandleGetTaggedPost)
		}
		userApi := api.Group("/user")
		{
			userApi.GET("/get", service.HandleGetUser)
			userApi.POST("/changePwd", service.HandleUserChangePwd)
			userApi.POST("/edit", service.HandleUserEdit)
			userApi.DELETE("/delete", service.HandleUserDelete)
			userApi.GET("/heatmap", service.HandleUserHeatMap)
			userApi.POST("/follow", service.HandleUserFollow)
			userApi.POST("/unfollow", service.HandleUserUnfollow)
			userApi.GET("/follower", service.HandlerGetUserFollower)
			userApi.GET("/following", service.HandlerGetUserFollowing)
			userApi.GET("/avatar/:name", service.HandleGetAvatar)
		}
		fileApi := api.Group("/file")
		{
			fileApi.GET("/download/:name", service.HandleGetFile)
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
		searchApi := api.Group("/search")
		{
			searchApi.GET("/user", service.HandleUserSearch)
			searchApi.GET("/post", service.HandlePostSearch)
		}
	}
	e.Logger.Fatal(e.Start(fmt.Sprintf(":%d", mServer.Config.ServerConfig.Port)))
}
