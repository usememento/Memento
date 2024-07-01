package model

import (
	"gorm.io/gorm"
	"time"
)

type Post struct {
	gorm.Model
	Liked      int64
	CreatedAt  time.Time
	EditedAt   time.Time
	ContentUrl string
}
