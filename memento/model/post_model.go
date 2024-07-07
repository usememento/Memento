package model

import (
	"gorm.io/gorm"
	"time"
)

type Post struct {
	gorm.Model
	IsPrivate    bool
	Username     string
	TotalLiked   int64
	CreatedAt    time.Time
	EditedAt     time.Time
	TotalComment int64
	ContentUrl   string
	Comments     []Comment
	Tags         []*Tag `gorm:"many2many:post_tags;"`
}

type PostViewModel struct {
	IsLiked      bool
	IsPrivate    bool
	PostID       uint
	User         UserViewModel
	TotalLiked   int64
	TotalComment int64
	CreatedAt    time.Time
	EditedAt     time.Time
	Content      string
}
