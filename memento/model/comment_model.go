package model

import (
	"gorm.io/gorm"
	"time"
)

type Comment struct {
	gorm.Model
	PostID    uint
	Username  string
	CreatedAt time.Time
	EditedAt  time.Time
	Content   string
	Liked     int64
}

type CommentViewModel struct {
	PostID    uint
	Username  string
	CreatedAt time.Time
	EditedAt  time.Time
	Content   string
	Liked     int64
}
