package model

import (
	"gorm.io/gorm"
	"time"
)

type Post struct {
	gorm.Model
	Id         int64 `gorm:"primaryKey"`
	UserId     int64
	User       User
	Liked      int64
	CreatedAt  time.Time
	EditedAt   time.Time
	ContentUrl string
}
