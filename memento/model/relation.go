package model

import "gorm.io/gorm"

type UserPost struct {
	gorm.Model
	UserId uint
	User   User
	PostId uint
	Post   Post
}

type UserLike struct {
	gorm.Model
	UserId uint
	User   User
	PostId uint
	Post   Post
}

type PostFile struct {
	gorm.Model
	PostId  uint
	Post    Post
	FileUrl string
}

type UserFollow struct {
	gorm.Model
	UserId   uint
	User     User
	FollowId uint
	Follow   User
}

type PostTag struct {
	gorm.Model
	PostId uint
	Post   Post
	TagId  uint
	Tag    Tag
}
