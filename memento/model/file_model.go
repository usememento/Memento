package model

import (
	"time"

	"gorm.io/gorm"
)

type File struct {
	gorm.Model
	Username   string
	Filename   string
	ContentUrl string
}

type FileViewModel struct {
	ID       uint      `json:"id"`
	Filename string    `json:"filename"`
	Time     time.Time `json:"time"`
}
