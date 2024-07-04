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
	contentData, _ := os.ReadFile(contentFilepath)
	contentTags := utils.GetTags(string(contentData))
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			// add all non-existing tags to database
			for _, t := range contentTags {
				var tag model.Tag
				err := tx.Where("name=?", t).FirstOrCreate(&tag).Error
				if err != nil {
					log.Errorf(err.Error())
					return utils.RespondError(c, "unknown insertion error")
				}
				tx.Model(&tag).Association("Posts").Append(&post)
			}
			err = tx.Create(&post).Error
			tx.Model(&post).Association("Tags").Append(contentTags)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			tx.Model(&user).Association("Posts").Append(&post)
			user.TotalPosts += 1
			tx.Save(&user)
			tx.Save(&post)
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
			var tags []model.Tag
			tx.Model(&post).Association("Tags").Find(&tags)
			for _, tag := range tags {
				tx.Model(&tag).Association("Posts").Delete(&post)
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
	os.Remove(post.ContentUrl)
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
	oldContent, _ := os.ReadFile(post.ContentUrl)
	oldTags := utils.GetTags(string(oldContent))
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
	newContent, _ := os.ReadFile(post.ContentUrl)
	newTags := utils.GetTags(string(newContent))
	tagsToAdd, tagsToDel := utils.CalcTagsDiff(oldTags, newTags)
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			for _, t := range tagsToAdd {
				var tag model.Tag
				if err := tx.Where("name=?", t).FirstOrCreate(&tag).Error; err != nil {
					continue
				}
				tx.Model(&tag).Association("Posts").Append(&post)
			}
			for _, tag := range tagsToDel {
				tx.Model(&post).Association("Tags").Delete(&tag)
			}
			err = memento.GetDbConnection().Model(&post).Update("edited_at", time.Now()).Error
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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

func HandleGetTaggedPost(c echo.Context) error {
	return nil
}
