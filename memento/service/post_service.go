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
	"strconv"
	"time"
)

func HandlePostCreate(c echo.Context) error {
	log.Info("HandlePostCreate: %s", c.RealIP())
	username := c.FormValue("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	now := time.Now()
	post := model.Post{
		Username:  user.Username,
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
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err = tx.Create(&post).Error
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			tx.Model(&user).Association("Posts").Append(&post)
			user.TotalPosts += 1
			tx.Save(&user)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}
	return utils.RespondOk(c, strconv.FormatInt(int64(post.ID), 10))
}
func HandlePostDelete(c echo.Context) error {
	id := c.FormValue("id")
	var post model.Post
	if err := memento.GetDbConnection().First(&post, "id=?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err := memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			var user model.User
			err := tx.First(&user, "username=?", post.Username).Error
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			err = tx.Model(&user).Association("Posts").Delete(&post)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			if err = tx.Delete(&post).Error; err != nil {
				log.Errorf(err.Error())
				return err
			}
			user.TotalPosts -= 1
			tx.Save(&user)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown deletion error")
	}
	return c.NoContent(http.StatusOK)
}
func HandlePostEdit(c echo.Context) error {
	id := c.FormValue("id")
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
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
	return c.NoContent(http.StatusOK)
}
func HandlePostGet(c echo.Context) error {
	id := c.QueryParam("id")
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
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
		Username  string
		Liked     int64
		CreatedAt time.Time
		EditedAt  time.Time
		Content   string
	}{
		Id:        post.ID,
		Username:  post.Username,
		Liked:     post.Liked,
		CreatedAt: post.CreatedAt,
		EditedAt:  post.EditedAt,
		Content:   string(content),
	})
}

func HandleGetUserPosts(c echo.Context) error {
	username := c.QueryParam("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	var posts []model.Post
	err = memento.GetDbConnection().Model(&user).Association("Posts").Find(&posts)
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	var ids []model.PostViewModel
	for _, post := range posts {
		ids = append(ids, model.PostViewModel{
			Username:   post.Username,
			Liked:      post.Liked,
			CreatedAt:  post.CreatedAt,
			EditedAt:   post.EditedAt,
			ContentUrl: post.ContentUrl,
		})
	}
	return c.JSON(http.StatusOK, ids)
}

func HandlePostLike(c echo.Context) error {
	return nil
}

func HandlePostCancelLike(c echo.Context) error {
	return nil
}
