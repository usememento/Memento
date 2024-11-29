package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/query"
	"Memento/memento/utils"
	"errors"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
	"net/http"
	"strconv"
	"time"
)

func HandleCommentCreate(c echo.Context) error {
	username := c.Get("username").(string)
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	postId := c.FormValue("id")
	content := c.FormValue("content")

	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	id, err := strconv.ParseUint(postId, 10, 64)
	if err != nil {
		return utils.RespondError(c, "Invalid post id")
	}
	post, err := query.Post.Where(query.Post.ID.Eq(uint(id))).First()
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
	err = memento.Db().Transaction(
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
			post.TotalComment += 1
			tx.Save(&user)
			tx.Save(&post)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.JSON(http.StatusOK, utils.CommentToView(&comment, utils.UserToView(user, false), false))
}

func HandleCommentEdit(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	commentId := c.FormValue("id")
	content := c.FormValue("content")
	id, err := strconv.ParseUint(commentId, 10, 64)
	if err != nil {
		return utils.RespondError(c, "Invalid post id")
	}
	comment, err := query.Comment.Where(query.Comment.ID.Eq(uint(id))).First()
	if comment.Username != username {
		return utils.RespondError(c, "permission denied")
	}
	comment.EditedAt = time.Now()
	comment.Content = content
	memento.Db().Save(&comment)
	return nil
}

func HandleCommentDelete(c echo.Context) error {
	username := c.Get("username").(string)
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	commentId := c.FormValue("id")
	var comment model.Comment
	err := memento.Db().First(&comment, "id=?", commentId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "comment not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if comment.Username != username {
		return utils.RespondError(c, "permission denied")
	}
	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var post model.Post
	err = memento.Db().First(&post, "id=?", comment.PostID).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.Db().Transaction(
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
			post.TotalComment -= 1
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}

func HandleCommentLike(c echo.Context) error {
	commentId := c.FormValue("id")
	username := c.Get("username").(string)
	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
		return utils.RespondError(c, "user not exists")
	}
	var likedComments []model.Comment
	err = memento.Db().Model(&user).Association("LikedComments").Find(&likedComments)
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	id, err := strconv.Atoi(commentId)
	if err != nil {
		return utils.RespondError(c, "invalid comment id")
	}
	for _, comm := range likedComments {
		if comm.ID == uint(id) {
			return utils.RespondError(c, "already liked")
		}
	}

	var comment model.Comment
	memento.Db().First(&comment, "id=?", commentId)
	err = memento.Db().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("LikedComments").Append(&comment)
			if err != nil {
				return err
			}
			comment.Liked += 1
			tx.Save(&comment)
			tx.Save(&user)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}
func HandleCommentCancelLike(c echo.Context) error {
	commentId := c.FormValue("id")
	var comment model.Comment
	memento.Db().First(&comment, "id=?", commentId)
	err := memento.Db().Transaction(
		func(tx *gorm.DB) error {
			comment.Liked -= 1
			tx.Save(&comment)
			return nil
		})
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}

func HandleGetPostComments(c echo.Context) error {
	postId := c.QueryParam("id")
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var post model.Post
	err = memento.Db().First(&post, "id=?", postId).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	comments := make([]model.Comment, 0, memento.PageSize)
	err = memento.Db().
		Model(&post).
		Association("Comments").
		Find(
			&comments,
			memento.Db().
				Order("created_at desc").
				Offset(page*memento.PageSize).
				Limit(memento.PageSize))
	total := memento.Db().Model(&post).Association("Comments").Count()
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.CommentViewModel, 0, memento.PageSize)
	for _, comm := range comments {
		var user model.User
		memento.Db().First(&user, "username=?", comm.Username)
		var likedComments []model.Comment
		err = memento.Db().
			Model(&user).
			Association("LikedComments").
			Find(&likedComments, "id=?", comm.ID)
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
		result = append(
			result,
			*utils.CommentToView(
				&comm,
				utils.UserToView(
					&user,
					checkIsFollowed(
						c.Get("username").(string),
						user.Username)),
				len(likedComments) > 0))
	}
	return c.JSON(http.StatusOK, map[string]interface{}{
		"comments": result,
		"maxPage":  utils.MaxPage(total),
	})
}

func HandleGetUserComments(c echo.Context) error {
	currentUsername := c.Get("username")
	var currentUser model.User
	if currentUsername != "" {
		memento.Db().First(&currentUser, "username=?", currentUsername)
	}
	username := c.QueryParam("username")
	findPublic := username != currentUsername
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var user model.User
	err = memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "user not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	comments := make([]model.Comment, 0, memento.PageSize)
	if !findPublic {
		err = memento.Db().
			Model(&user).
			Association("Comments").
			Find(
				&comments,
				memento.Db().
					Order("created_at desc").
					Offset(page*memento.PageSize).
					Limit(memento.PageSize))
	} else {
		err = memento.Db().
			Joins("JOIN posts ON posts.id = comments.post_id AND posts.is_private = false").
			Order("comments.created_at desc").
			Offset(page * memento.PageSize).
			Limit(memento.PageSize).
			Find(&comments).
			Error
	}
	total := memento.Db().Model(&user).Association("Comments").Count()
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.CommentWithPost, 0, memento.PageSize)
	for _, comm := range comments {
		var post model.Post
		memento.Db().First(&post, "id=?", comm.PostID)
		var likedPosts []model.Post
		if currentUsername != "" {
			err = memento.Db().
				Model(&currentUser).
				Association("LikedPosts").
				Find(&likedPosts, "id=?", post.ID)
			if err != nil {
				return utils.RespondError(c, "unknown query error")
			}
		}
		postView, err := utils.PostToView(
			&post,
			utils.UserToView(
				&user,
				checkIsFollowed(c.Get("username").(string), user.Username)),
			len(likedPosts) > 0)
		if err != nil {
			log.Errorf(err.Error())
			return utils.RespondError(c, "unknown query error")
		}
		var likedComments []model.Comment
		if currentUsername != "" {
			err = memento.Db().
				Model(&currentUser).
				Association("LikedComments").
				Find(&likedComments, "id=?", comm.ID)
			if err != nil {
				return utils.RespondError(c, "unknown query error")
			}
		}
		result = append(result, model.CommentWithPost{
			Comment: *utils.CommentToView(
				&comm,
				utils.UserToView(
					&user,
					checkIsFollowed(c.Get("username").(string), user.Username)),
				len(likedComments) > 0),
			Post: *postView,
		})
	}
	return c.JSON(http.StatusOK, map[string]interface{}{
		"comments": result,
		"maxPage":  utils.MaxPage(total),
	})
}
