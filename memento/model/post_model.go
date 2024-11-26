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
	IsLiked      bool          `json:"isLiked"`
	IsPrivate    bool          `json:"isPrivate"`
	PostID       uint          `json:"postID"`
	User         UserViewModel `json:"user"`
	TotalLiked   int64         `json:"totalLiked"`
	TotalComment int64         `json:"totalComment"`
	CreatedAt    time.Time     `json:"createdAt"`
	EditedAt     time.Time     `json:"editedAt"`
	Content      string        `json:"content"`
}
