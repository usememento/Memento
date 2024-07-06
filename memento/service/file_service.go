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

func HandleFileUpload(c echo.Context) error {
	now := time.Now()
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	var user model.User
	if err := memento.GetDbConnection().First(&user, "username=?", username).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	file, err := c.FormFile("file")
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "can not read form file")
	}

	src, err := file.Open()
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "form file open error")
	}
	defer src.Close()
	ext := path.Ext(file.Filename)
	filename := utils.Md5string(fmt.Sprintf("%d%s", now.UnixMilli(), file.Filename)) + ext
	filepath := path.Join(memento.GetFilePath(), filename)
	// Destination
	dst, err := os.Create(filepath)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer dst.Close()
	// Copy
	if _, err = io.Copy(dst, src); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			file := model.File{
				Username:   user.Username,
				Filename:   filename,
				ContentUrl: filepath,
			}
			err := tx.Model(&user).Association("Files").Append(&file)
			if err != nil {
				return err
			}
			user.TotalFiles += 1
			tx.Save(&user)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown transaction error")
	}
	return utils.RespondOk(c, filepath)
}

func HandleFileDelete(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	filepath := c.FormValue("url")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var file model.File
	err = memento.GetDbConnection().First(&file, "content_url=?", filepath).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "url not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Files").Delete(&file)
			if err != nil {
				return err
			}
			user.TotalFiles -= 1
			tx.Save(&user)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown transaction error")
	}
	os.Remove(file.ContentUrl)
	return c.NoContent(http.StatusOK)
}

func HandleGetFile(c echo.Context) error {
	url := c.QueryParam("url")
	return c.File(url)
}
