package model

import (
	"gorm.io/gorm"
	"time"
)

type User struct {
	gorm.Model
	Username     string `gorm:"uniqueIndex"`
	PasswordHash string
	AvatarUrl    string
	Nickname     string
	Bio          string
	TotalLiked   int64
	TotalComment int64
	TotalPosts   int64
	RegisteredAt time.Time
}
