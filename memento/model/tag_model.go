package model

import "gorm.io/gorm"

type Tag struct {
	gorm.Model
	Name  string  `gorm:"uniqueIndex"`
	Posts []*Post `gorm:"many2many:post_tags;"`
}
