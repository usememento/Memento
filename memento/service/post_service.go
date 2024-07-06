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
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
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
	content, err := os.OpenFile(contentFilepath, os.O_CREATE|os.O_RDWR, 0777)
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
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	id := c.FormValue("id")
	var post model.Post
	if err := memento.GetDbConnection().First(&post, "id=?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if post.Username != username {
		return utils.RespondError(c, "permission denied")
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
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
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
	if post.Username != username {
		return utils.RespondError(c, "permission denied")
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
func HandleGetPost(c echo.Context) error {
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
	return c.JSON(http.StatusOK, model.PostViewModel{
		PostID:    post.ID,
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
	err = memento.GetDbConnection().Model(&user).Association("Posts").Find(&posts, memento.GetDbConnection())
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.PostViewModel, 0, len(posts))
	for _, post := range posts {
		pv, err := utils.PostToView(&post)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
}

func HandlePostLike(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	postId := c.FormValue("post_id")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var post model.Post
	err = memento.GetDbConnection().First(&post, "id=?", postId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var likedPost model.Post
	err = memento.GetDbConnection().Model(&user).Association("Likes").Find(&likedPost, "id=?", post.ID)
	if err == nil {
		return utils.RespondError(c, "already liked")
	} else {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "unknown query error")
		}
	}
	var author model.User
	err = memento.GetDbConnection().First(&author, "username=?", post.Username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Likes").Append(&post)
			if err != nil {
				return err
			}
			post.Liked += 1
			author.TotalLiked += 1
			tx.Save(&post)
			tx.Save(&user)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}

func HandlePostCancelLike(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	postId := c.FormValue("post_id")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var post model.Post
	err = memento.GetDbConnection().First(&post, "id=?", postId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var likedPost model.Post
	err = memento.GetDbConnection().Model(&user).Association("Likes").Find(&likedPost, "id=?", post.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "not liked yet")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var author model.User
	err = memento.GetDbConnection().First(&author, "username=?", post.Username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Likes").Delete(&post)
			if err != nil {
				return err
			}
			post.Liked -= 1
			author.TotalLiked -= 1
			tx.Save(&post)
			tx.Save(&user)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}

func HandleGetTaggedPost(c echo.Context) error {
	t := c.QueryParam("tag")
	var tag model.Tag
	err := memento.GetDbConnection().First(&tag, "name=?", t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var posts []model.Post
	memento.GetDbConnection().Model(&tag).Association("Posts").Find(&posts)
	var result []model.PostViewModel
	for _, p := range posts {
		pv, err := utils.PostToView(&p)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
}
