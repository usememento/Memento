package model

import "gorm.io/gorm"

type UserPost struct {
	gorm.Model
	UserId int64
	User   User
	PostId int64
	Post   Post
}

type UserLike struct {
	gorm.Model
	UserId int64
	User   User
	PostId int64
	Post   Post
}
