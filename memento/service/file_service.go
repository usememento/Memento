package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/query"
	"Memento/memento/utils"
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
)

func HandleFileUpload(c echo.Context) error {
	now := time.Now()
	username := c.Get("username").(string)
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
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
	defer func(src multipart.File) {
		err := src.Close()
		if err != nil {
			log.Errorf(err.Error())
		}
	}(src)
	ext := path.Ext(file.Filename)
	filename := utils.Md5string(fmt.Sprintf("%d%s", now.UnixMilli(), file.Filename)) + ext
	filepath := path.Join(memento.GetUploadPath(), filename)
	// Destination
	dst, err := os.Create(filepath)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer func(dst *os.File) {
		err := dst.Close()
		if err != nil {
			log.Errorf(err.Error())
		}
	}(dst)
	// Copy
	if _, err = io.Copy(dst, src); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}
	file0 := model.File{
		Username:   user.Username,
		Filename:   file.Filename,
		ContentUrl: filepath,
	}
	err = memento.Db().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Files").Append(&file0)
			if err != nil {
				return err
			}
			user.TotalFiles += 1
			tx.Save(&user)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown error")
	}
	return c.JSON(200, echo.Map{
		"Filename": file.Filename,
		"ID":       file0.ID,
	})
}

func HandleFileDelete(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	id := c.Param("id")
	var user model.User
	err := memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var file model.File
	err = memento.Db().First(&file, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "url not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.Db().Transaction(
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
		return utils.RespondInternalError(c, "unknown transaction error")
	}
	_ = os.Remove(file.ContentUrl)
	return c.NoContent(http.StatusOK)
}

func HandleGetFile(c echo.Context) error {
	id := c.Param("id")
	var file model.File
	err := memento.Db().First(&file, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "file not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	return c.Inline(file.ContentUrl, file.Filename)
}

func HandleGetResourcesList(c echo.Context) error {
	username := c.Get("username")
	pageStr := c.QueryParam("page")
	page, err := strconv.Atoi(pageStr)
	if err != nil {
		return utils.RespondError(c, "Invalid page")
	}
	var user model.User
	err = memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "User not found")
	}
	var files []model.File
	err = memento.Db().Order("created_at DESC").Offset(page*memento.PageSize).Limit(memento.PageSize).Find(&files, "username=?", username).Error
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "Failed to find files")
	}
	var total int64
	err = memento.Db().Table("files").Select("username=?", username).Count(&total).Error
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "Failed to find files")
	}
	result := make([]model.FileViewModel, len(files))

	for index, file := range files {
		result[index] = model.FileViewModel{
			ID:       file.ID,
			Filename: file.Filename,
			Time:     file.CreatedAt,
		}
	}

	return c.JSON(200, echo.Map{
		"files":   result,
		"maxPage": utils.MaxPage(total),
	})
}
