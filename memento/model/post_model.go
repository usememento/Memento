package model

import (
	"gorm.io/gorm"
	"time"
)

type Post struct {
	gorm.Model
	UserId     uint
	User       User
	Liked      int64
	CreatedAt  time.Time
	EditedAt   time.Time
	ContentUrl string
}
