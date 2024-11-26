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
	CommentID uint          `json:"commentId"`
	PostID    uint          `json:"postId"`
	User      UserViewModel `json:"user"`
	CreatedAt time.Time     `json:"createdAt"`
	EditedAt  time.Time     `json:"editedAt"`
	Content   string        `json:"content"`
	Liked     int64         `json:"liked"`
	IsLiked   bool          `json:"isLiked"`
}

type CommentWithPost struct {
	Comment CommentViewModel `json:"comment"`
	Post    PostViewModel    `json:"post"`
}
