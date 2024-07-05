package model

import (
	"gorm.io/gorm"
	"time"
)

type Post struct {
	gorm.Model
	Username   string
	Liked      int64
	CreatedAt  time.Time
	EditedAt   time.Time
	ContentUrl string
	Comments   []Comment
	Tags       []*Tag `gorm:"many2many:post_tags;"`
}

type PostViewModel struct {
	PostID    uint
	Username  string
	Liked     int64
	CreatedAt time.Time
	EditedAt  time.Time
	Content   string
}
