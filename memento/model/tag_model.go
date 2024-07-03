package model

import "gorm.io/gorm"

type Tag struct {
	gorm.DB
	Name string
}
