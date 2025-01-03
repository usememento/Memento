package main

import (
	"Memento/memento"
	"Memento/memento/query"
	"Memento/memento/service"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"github.com/labstack/gommon/log"
)

func main() {
	err := memento.Init()
	query.SetDefault(memento.Db())
	if err != nil {
		log.Errorf("Error initializing memento server: %s\n", err.Error())
		return
	}
	fmt.Println(memento.GetConfig().ServerConfig)
	e := echo.New()
	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Gzip())
	e.Use(service.SEOFrontEndMiddleware)
	e.Use(middleware.CORS())

	e.GET("/rss/:username", service.HandleRss)

	api := e.Group("/api")
	{
		api.Use(memento.TokenValidator())
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
			postApi.GET("/likedPosts", service.HandleGetLikedPosts)
			postApi.GET("/tags", service.HandleGetTags)
			postApi.GET("/following", service.HandleGetFollowingPosts)
		}
		userApi := api.Group("/user")
		{
			userApi.POST("/refresh", service.HandleRefreshToken)
			userApi.POST("/login", service.HandleLogin)
			userApi.POST("/create", service.HandleCreate)
			userApi.GET("/get", service.HandleGetUser)
			userApi.POST("/changePwd", service.HandleUserChangePwd)
			userApi.POST("/edit", service.HandleUserEdit)
			userApi.DELETE("/:username", service.HandleUserDelete)
			userApi.GET("/heatmap", service.HandleUserHeatMap)
			userApi.POST("/follow", service.HandleUserFollow)
			userApi.POST("/unfollow", service.HandleUserUnfollow)
			userApi.GET("/follower", service.HandlerGetUserFollower)
			userApi.GET("/following", service.HandlerGetUserFollowing)
			userApi.GET("/avatar/:name", service.HandleGetAvatar)
		}
		fileApi := api.Group("/file")
		{
			fileApi.GET("/download/:id", service.HandleGetFile)
			fileApi.POST("/upload", service.HandleFileUpload)
			fileApi.DELETE("/delete/:id", service.HandleFileDelete)
			fileApi.GET("/all", service.HandleGetResourcesList)
		}
		commentApi := api.Group("/comment")
		{
			commentApi.POST("/create", service.HandleCommentCreate)
			commentApi.POST("/edit", service.HandleCommentEdit)
			commentApi.DELETE("/delete", service.HandleCommentDelete)
			commentApi.POST("/like", service.HandleCommentLike)
			commentApi.POST("/unlike", service.HandleCommentCancelLike)
			commentApi.GET("/postComments", service.HandleGetPostComments)
			commentApi.GET("/userComments", service.HandleGetUserComments)
		}
		searchApi := api.Group("/search")
		{
			searchApi.GET("/user", service.HandleUserSearch)
			searchApi.GET("/post", service.HandlePostSearch)
		}
		adminApi := api.Group("/admin")
		{
			adminApi.Use(service.AdminCheck)
			adminApi.GET("/config", service.HandleGetConfigs)
			adminApi.POST("/config", service.HandleSetConfig)
			adminApi.GET("/listUsers", service.HandleListUsers)
			adminApi.DELETE("/deleteUser/:username", service.HandleAdminDeleteUser)
			adminApi.POST("/setPermission", service.HandleSetUserPermission)
			adminApi.POST("/setIcon", service.HandleSetNewIcon)
		}
		captchaApi := api.Group("/captcha")
		{
			captchaApi.GET("/create", service.HandleGetCaptcha)
			captchaApi.POST("/verify", service.HandleVerifyCaptcha)
		}
	}

	public := e.Group("/public")
	{
		public.GET("/article/:id", service.HandlePublicArticle)
	}

	e.Logger.Fatal(e.Start(fmt.Sprintf("0.0.0.0:1323")))
}
