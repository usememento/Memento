package model

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	Username      string `gorm:"uniqueIndex"`
	PasswordHash  string
	PasswordRetry int
	LockUntil     time.Time
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
}

type UserViewModel struct {
	Username      string    `json:"username"`
	Nickname      string    `json:"nickname"`
	Bio           string    `json:"bio"`
	TotalLiked    int64     `json:"totalLiked"`
	TotalComment  int64     `json:"totalComment"`
	TotalPosts    int64     `json:"totalPosts"`
	TotalFiles    int64     `json:"totalFiles"`
	TotalFollower int64     `json:"totalFollower"`
	TotalFollows  int64     `json:"totalFollows"`
	RegisteredAt  time.Time `json:"registeredAt"`
	Avatar        string    `json:"avatar"`
	IsFollowed    bool      `json:"isFollowed"`
	IsAdmin       bool      `json:"isAdmin"`
}
