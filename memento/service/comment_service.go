package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
	"net/http"
	"time"
)

func HandleCommentCreate(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	postId := c.FormValue("post_id")
	content := c.FormValue("content")

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
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	now := time.Now()
	comment := model.Comment{
		PostID:    post.ID,
		Username:  user.Username,
		CreatedAt: now,
		EditedAt:  now,
		Content:   content,
		Liked:     0,
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			tx.Create(&comment)
			err := tx.Model(&user).Association("Comments").Append(&comment)
			if err != nil {
				return err
			}
			err = tx.Model(&post).Association("Comments").Append(&comment)
			if err != nil {
				return err
			}
			user.TotalComment += 1
			tx.Save(&user)
			tx.Save(&post)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return utils.RespondOk(c, comment.ID)
}

func HandleCommentEdit(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	commentId := c.FormValue("comment_id")
	content := c.FormValue("content")
	var comment model.Comment
	memento.GetDbConnection().First(&comment, "id=?", commentId)
	if comment.Username != username {
		return utils.RespondError(c, "permission denied")
	}
	comment.EditedAt = time.Now()
	comment.Content = content
	memento.GetDbConnection().Save(&comment)
	return nil
}

func HandleCommentDelete(c echo.Context) error {
	commentId := c.FormValue("comment_id")
	var comment model.Comment
	err := memento.GetDbConnection().First(&comment, "id=?", commentId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "comment not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	username := c.Get("username")
	if username == "" {
		return utils.RespondError(c, "invalid token")
	}
	if comment.Username != username {
		utils.RespondError(c, "permission denied")
	}
	var user model.User
	err = memento.GetDbConnection().First(&user, "username=?", comment.Username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var post model.Post
	err = memento.GetDbConnection().First(&post, "id=?", comment.PostID).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Comments").Delete(&comment)
			if err != nil {
				return err
			}
			err = tx.Model(&post).Association("Comments").Delete(&comment)
			if err != nil {
				return err
			}
			tx.Delete(&comment)
			user.TotalComment -= 1
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}

func HandleCommentLike(c echo.Context) error {
	commentId := c.FormValue("comment_id")
	var comment model.Comment
	memento.GetDbConnection().First(&comment, "id=?", commentId)
	memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			comment.Liked += 1
			tx.Save(&comment)
			return nil
		})
	return nil
}
func HandleCommentCancelLike(c echo.Context) error {
	commentId := c.FormValue("comment_id")
	var comment model.Comment
	memento.GetDbConnection().First(&comment, "id=?", commentId)
	memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			comment.Liked -= 1
			tx.Save(&comment)
			return nil
		})
	return nil
}

func HandleGetPostComments(c echo.Context) error {
	postId := c.QueryParam("post_id")
	var post model.Post
	err := memento.GetDbConnection().First(&post, "id=?", postId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var comments []model.Comment
	err = memento.GetDbConnection().Model(&post).Association("Comments").Find(&comments)
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	var result []model.CommentViewModel
	for _, comm := range comments {
		result = append(result, *utils.CommentToView(&comm))
	}
	return c.JSON(http.StatusOK, result)
}
