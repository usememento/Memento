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
	ID       uint
	Filename string
	Time     time.Time
}
