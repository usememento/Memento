package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
	"io"
	"net/http"
	"os"
	"path"
	"time"
)

func HandlePostCreate(c echo.Context) error {
	log.Info("HandlePostCreate: %s", c.RealIP())
	username := c.FormValue("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	now := time.Now()
	post := model.Post{
		UserId:    user.ID,
		Liked:     0,
		CreatedAt: now,
		EditedAt:  now,
	}
	contentFile, err := c.FormFile("content")
	if err != nil {
		return utils.RespondError(c, "post content not uploaded")
	}
	contentFilename := utils.Md5string(fmt.Sprintf("%d%s", now.UnixMilli(), contentFile.Filename)) + ".md"
	contentFilepath := path.Join(memento.GetPostPath(), contentFilename)
	contentBody, err := contentFile.Open()
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "can not open content file")
	}
	defer contentBody.Close()
	content, err := os.Create(contentFilepath)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer content.Close()

	if _, err = io.Copy(content, contentBody); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}
	post.ContentUrl = contentFilepath
	err = memento.GetDbConnection().Create(&post).Error
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}
	return utils.RespondOk(c, "post created")
}
func HandlePostDelete(c echo.Context) error {
	id := c.FormValue("id")
	var user model.User
	err := memento.GetDbConnection().First(&user, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return utils.RespondError(c, fmt.Sprintf("post id %s not exists", id))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if err := memento.GetDbConnection().Delete(&user).Error; err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown deletion error")
	}
	return utils.RespondOk(c, "delete succeeded")
}
func HandlePostEdit(c echo.Context) error {
	id := c.QueryParam("id")
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, fmt.Sprintf("post id %s not exists", id))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	contentFile, err := c.FormFile("content")
	if err != nil {
		return utils.RespondError(c, "post content not uploaded")
	}
	contentBody, err := contentFile.Open()
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "can not open content file")
	}
	defer contentBody.Close()
	contentFilepath := post.ContentUrl
	content, err := os.Create(contentFilepath)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer content.Close()

	if _, err = io.Copy(content, contentBody); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}

	err = memento.GetDbConnection().Model(&post).Update("edited_at", time.Now()).Error
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown update error")
	}
	return utils.RespondOk(c, "post edited")
}
func HandlePostGet(c echo.Context) error {
	id := c.QueryParam("id")
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, fmt.Sprintf("post id %s not exists", id))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	content, err := os.ReadFile(post.ContentUrl)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "cannot read post content")
	}
	return c.JSON(http.StatusOK, struct {
		Id        uint
		UserId    uint
		Liked     int64
		CreatedAt time.Time
		EditedAt  time.Time
		Content   string
	}{
		Id:        post.ID,
		UserId:    post.UserId,
		Liked:     post.Liked,
		CreatedAt: post.CreatedAt,
		EditedAt:  post.EditedAt,
		Content:   string(content),
	})
}
