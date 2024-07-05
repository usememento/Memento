package model

import (
	"gorm.io/gorm"
	"time"
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
	Posts         []Post    `gorm:"foreignKey:Username;references:Username"`
	Files         []File    `gorm:"foreignKey:Username;references:Username"`
	Follows       []User    `gorm:"foreignKey:Username;references:Username"`
	Followers     []User    `gorm:"foreignKey:Username;references:Username"`
	Likes         []Post    `gorm:"foreignKey:Username;references:Username"`
	Comments      []Comment `gorm:"foreignKey:Username;references:Username"`
}

type UserViewModel struct {
	Username     string
	Nickname     string
	Bio          string
	TotalLiked   int64
	TotalComment int64
	TotalPosts   int64
	RegisteredAt time.Time
	AvatarUrl    string
}
