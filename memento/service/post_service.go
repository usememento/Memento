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
	"strings"
	"time"
)

func HandlePostCreate(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	permission := c.FormValue("permission")
	private := false
	if permission == "private" {
		private = true
	} else if permission == "public" {
		private = false
	} else {
		return utils.RespondError(c, "invalid permission level")
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
		IsPrivate:    private,
		Username:     user.Username,
		TotalLiked:   0,
		CreatedAt:    now,
		EditedAt:     now,
		TotalComment: 0,
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
			tx.Save(&post)
			// add all non-existing tags to database
			for _, t := range contentTags {
				log.Info(t)
				var tag model.Tag
				tag.Name = t
				err := tx.First(&tag, "name=?", t).Error
				if err != nil {
					if errors.Is(err, gorm.ErrRecordNotFound) {
						tx.Create(&tag)
					} else {
						log.Errorf(err.Error())
						return utils.RespondError(c, "unknown insertion error")
					}
				}
				err = tx.Model(&user).Association("Tags").Append(&tag)
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
				tx.Model(&tag).Association("Posts").Append(&post)
			}
			err = tx.Model(&post).Association("Tags").Append(contentTags)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			err = tx.Model(&user).Association("Posts").Append(&post)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			user.TotalPosts += 1
			tx.Save(&user)
			tx.Save(&post)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}
	var likePosts []model.Post
	memento.GetDbConnection().Model(&user).Association("likes").Find(&likePosts, "id=?", post.ID)
	//log.Info(likePosts[0].ID)
	pv, err := utils.PostToView(&post, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
	if err != nil {
		return utils.RespondError(c, "os open file error")
	}
	err = memento.IndexPost(&post)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondInternalError(c, "index failed")
	}
	return c.JSON(http.StatusOK, *pv)
}
func HandlePostDelete(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	id := c.Param("id")
	if id == "" {
		return utils.RespondError(c, "invalid post id")
	}
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
			tx.Delete(model.Comment{}, "post_id=?", post.ID)
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
		return utils.RespondUnauthorized(c)
	}
	id := c.FormValue("id")
	permission := c.FormValue("permission")
	private := false
	if permission == "private" {
		private = true
	} else if permission == "public" {
		private = false
	} else {
		return utils.RespondError(c, "invalid permission level")
	}
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", id).Error
	post.IsPrivate = private
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

	content, err := os.OpenFile(contentFilepath, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0777)
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
				tag.Name = t
				err := tx.First(&tag, "name=?", t).Error
				if err != nil {
					if errors.Is(err, gorm.ErrRecordNotFound) {
						tx.Create(&tag)
					} else {
						continue
					}
				}
				tx.Model(&tag).Association("Posts").Append(&post)
			}
			for _, tag := range tagsToDel {
				tx.Model(&post).Association("Tags").Delete(&tag)
			}
			post.EditedAt = time.Now()
			err = tx.Save(&post).Error
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
	var user model.User
	memento.GetDbConnection().First(&user, "username=?", post.Username)
	var likePosts []model.Post
	memento.GetDbConnection().Model(&user).Association("Likes").Find(&likePosts, "id=?", post.ID)
	pv, err := utils.PostToView(&post, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
	if err != nil {
		return utils.RespondError(c, "os open file error")
	}
	return c.JSON(http.StatusOK, *pv)
}

func HandleGetUserPosts(c echo.Context) error {
	userself := c.Get("username")
	username := c.QueryParam("username")
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var user model.User
	err = memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	if userself == username {
		err = memento.GetDbConnection().Where("username=?", username).Order("created_at desc").Offset(page * memento.PageSize).Limit(memento.PageSize).Find(&posts).Error
	} else {
		err = memento.GetDbConnection().Where("username=? and is_private=?", username, false).Order("created_at desc").Offset(page * memento.PageSize).Limit(memento.PageSize).Find(&posts).Error
	}
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, post := range posts {
		var likePosts []model.Post
		memento.GetDbConnection().Model(&user).Association("Likes").Find(&likePosts, "id=?", post.ID)
		pv, err := utils.PostToView(&post, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
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
		return utils.RespondUnauthorized(c)
	}
	postId := c.FormValue("id")
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
	var likedPost []model.Post
	memento.GetDbConnection().Model(&user).Association("Likes").Find(&likedPost, "id=?", post.ID)
	if len(likedPost) > 0 {
		log.Infof("liked post: %d", len(likedPost))
		return utils.RespondError(c, "already liked")
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
			post.TotalLiked += 1
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
		return utils.RespondUnauthorized(c)
	}
	postId := c.FormValue("id")
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
			post.TotalLiked -= 1
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
	if !strings.HasPrefix(t, "#") {
		t = "#" + t
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var tag model.Tag
	err = memento.GetDbConnection().First(&tag, "name=?", t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "tag not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	memento.GetDbConnection().Model(&tag).Order("created_at desc").Offset(page * memento.PageSize).Limit(memento.PageSize).Association("Posts").Find(&posts)
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var user model.User
		memento.GetDbConnection().First(&user, "username=?", p.Username)
		var likePosts []model.Post
		memento.GetDbConnection().Model(&user).Association("likes").Find(&likePosts, "id=?", p.ID)
		pv, err := utils.PostToView(&p, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
}

func HandleGetAllPosts(c echo.Context) error {
	username := c.Get("username")
	var currentUser model.User
	if username != "" {
		err := memento.GetDbConnection().First(&currentUser, "username=?", username).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	memento.GetDbConnection().Order("created_at desc").Offset(page*memento.PageSize).Limit(memento.PageSize).Find(&posts, "is_private=?", false)
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var user model.User
		memento.GetDbConnection().First(&user, "username=?", p.Username)
		isLiked := false
		if username != "" {
			var likePosts []model.Post
			err = memento.GetDbConnection().Model(&currentUser).Association("Likes").Find(&likePosts, "id=?", p.ID)
			if err != nil {
				log.Errorf(err.Error())
			}
			isLiked = len(likePosts) > 0
		}
		pv, err := utils.PostToView(&p, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), isLiked)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
}

func HandleGetLikedPosts(c echo.Context) error {
	currentUserName := c.Get("username")
	username := c.QueryParam("username")
	var currentUser model.User
	err := memento.GetDbConnection().First(&currentUser, "username=?", currentUserName).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var user model.User
	err = memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	memento.GetDbConnection().Model(&user).Order("created_at desc").Offset(page*memento.PageSize).Limit(memento.PageSize).Association("Likes").Find(&posts, "is_private=? or username=?", false, currentUserName)
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var author model.User
		memento.GetDbConnection().First(&author, "username=?", p.Username)
		isLiked := currentUserName == username
		if !isLiked {
			var likePosts []model.Post
			memento.GetDbConnection().Model(&currentUser).Association("likes").Find(&likePosts, "id=?", p.ID)
			isLiked = len(likePosts) > 0
		}
		pv, err := utils.PostToView(&p, utils.UserToView(&author, checkIsFollowed(c.Get("username").(string), author.Username)), isLiked)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
}

func HandleGetTags(c echo.Context) error {
	var tags []model.Tag
	t := c.QueryParam("type")
	if t == "all" {
		err := memento.GetDbConnection().Find(&tags).Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
	} else {
		username := c.Get("username")
		if username == "" {
			return utils.RespondUnauthorized(c)
		}
		var user model.User
		err := memento.GetDbConnection().First(&user, "username=?", username).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
		err = memento.GetDbConnection().Model(&user).Association("Tags").Find(&tags)
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
	}
	tagsList := make([]string, len(tags))
	for i, t := range tags {
		tagsList[i] = t.Name
	}
	return c.JSON(http.StatusOK, tagsList)
}
