package model

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username      string `gorm:"uniqueIndex"`
	PasswordHash  string
	AvatarUrl     string
	Nickname      string
	Bio           string
	TotalLiked    int64
	TotalComment  int64
	TotalPosts    int64
	TotalFiles    int64
	TotalFollower int64
	TotalFollows  int64
	RegisteredAt  time.Time
	IsAdmin       bool
	Posts         []Post    `gorm:"foreignKey:Username;references:Username"`
	Files         []File    `gorm:"foreignKey:Username;references:Username"`
	Follows       []User    `gorm:"many2many:user_follows;joinForeignKey:UserID;JoinReferences:FollowID"`
	Likes         []Post    `gorm:"many2many:user_liked_posts;foreignKey:Username;"`
	Comments      []Comment `gorm:"foreignKey:Username;references:Username"`
	LikedComments []Comment `gorm:"many2many:user_liked_comments;foreignKey:Username;"`
	Tags          []Tag     `gorm:"many2many:user_tags;foreignKey:Username;"`
}

type UserViewModel struct {
	Username      string
	Nickname      string
	Bio           string
	TotalLiked    int64
	TotalComment  int64
	TotalPosts    int64
	TotalFiles    int64
	TotalFollower int64
	TotalFollows  int64
	RegisteredAt  time.Time
	Avatar        string
	IsFollowed    bool
	IsAdmin       bool
}
