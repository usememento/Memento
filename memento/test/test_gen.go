package main

import (
	"Memento/memento"
	"Memento/memento/model"
	"gorm.io/gen"
)

func main() {
	g := gen.NewGenerator(gen.Config{
		OutPath: "../query",
		Mode:    gen.WithoutContext | gen.WithDefaultQuery | gen.WithQueryInterface, // generate mode
	})
	_ = memento.Init()
	// gormdb, _ := gorm.Open(mysql.Open("root:@(127.0.0.1:3306)/demo?charset=utf8mb4&parseTime=True&loc=Local"))
	g.UseDB(memento.Db()) // reuse your gorm db

	// Generate basic type-safe DAO API for struct `model.User` following conventions
	g.ApplyBasic(model.User{})
	g.ApplyBasic(model.Tag{})
	g.ApplyBasic(model.File{})
	g.ApplyBasic(model.Comment{})
	g.ApplyBasic(model.Post{})
	// Generate the code
	g.Execute()
}
