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
	CommentID uint
	PostID    uint
	User      UserViewModel
	CreatedAt time.Time
	EditedAt  time.Time
	Content   string
	Liked     int64
	IsLiked   bool
}
