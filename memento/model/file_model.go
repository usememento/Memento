package model

import "gorm.io/gorm"

type File struct {
	gorm.Model
	Username   string
	Filename   string
	ContentUrl string
}
