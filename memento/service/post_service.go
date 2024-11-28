package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/query"
	"Memento/memento/utils"
	"errors"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

func HandlePostCreate(c echo.Context) error {
	username := c.Get("username").(string)
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
	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}

	now := time.Now()
	post := &model.Post{
		IsPrivate:    private,
		Username:     user.Username,
		TotalLiked:   0,
		CreatedAt:    now,
		EditedAt:     now,
		TotalComment: 0,
	}
	content := c.FormValue("content")
	if content == "" {
		return utils.RespondError(c, "empty content")
	}
	contentFilename := utils.Md5string(fmt.Sprintf("%d%d", now.Unix(), rand.Int())) + ".md"
	subDir := utils.Md5string(fmt.Sprintf("%s%d", now.Month().String(), now.Year()))
	contentFilepath := filepath.Join(memento.GetPostPath(), subDir, contentFilename)
	subDirPath := filepath.Join(memento.GetPostPath(), subDir)
	if _, err := os.Stat(subDirPath); os.IsNotExist(err) {
		err = os.Mkdir(subDirPath, os.ModePerm)
		if err != nil {
			log.Errorf(err.Error())
			return utils.RespondError(c, "os file create error")
		}
	}

	file, err := os.OpenFile(contentFilepath, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0777)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer func(file *os.File) {
		_ = file.Close()
	}(file)
	if _, err = file.WriteString(content); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data write error")
	}

	post.ContentUrl = contentFilepath
	contentTags := utils.GetTags(content)
	err = query.Q.Transaction(
		func(tx *query.Query) error {
			tx.Post.Create(post)
			// add all non-existing tags to database
			for _, t := range contentTags {
				tag, err := tx.Tag.Where(tx.Tag.Name.Eq(t)).FirstOrCreate()
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
				tag.Posts = append(tag.Posts, post)
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
				tx.Tag.Updates(tag)
			}
			user.Posts = append(user.Posts, *post)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			user.TotalPosts += 1
			tx.User.Updates(user)

			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}
	pv, err := utils.PostToView(
		post,
		utils.UserToView(user, checkIsFollowed(c.Get("username").(string), user.Username)),
		false)
	if err != nil {
		return utils.RespondError(c, "os open file error")
	}
	err = memento.IndexPost(post)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondInternalError(c, "index failed")
	}
	defer onPostsChanged(username)
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
	if err := memento.Db().First(&post, "id=?", id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if post.Username != username {
		return utils.RespondError(c, "permission denied")
	}
	err := memento.Db().Transaction(
		func(tx *gorm.DB) error {
			var user model.User
			err := tx.First(&user, "username=?", post.Username).Error
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			var tags []model.Tag
			err = tx.Model(&post).Association("Tags").Find(&tags)
			if err != nil {
				log.Errorf(err.Error())
				return err
			}
			for _, tag := range tags {
				err = tx.Model(&tag).Association("Posts").Delete(&post)
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
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
			tx.Delete(&model.Comment{}, "post_id=?", post.ID)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown deletion error")
	}
	err = os.Remove(post.ContentUrl)
	if err != nil {
		log.Errorf(err.Error())
	}
	defer onPostsChanged(username.(string))
	return c.NoContent(http.StatusOK)
}
func HandlePostEdit(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	var user model.User
	err := memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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
	err = memento.Db().First(&post, "id=?", id).Error
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
	var oldTags1 []model.Tag
	err = memento.Db().Model(&post).Association("Tags").Find(&oldTags1)
	oldTags := make([]string, len(oldTags1))
	for i, t := range oldTags1 {
		oldTags[i] = t.Name
	}
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	content := c.FormValue("content")
	if content == "" {
		return utils.RespondError(c, "empty content")
	}
	contentFilepath := post.ContentUrl

	file, err := os.OpenFile(contentFilepath, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0777)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer func(file *os.File) {
		_ = file.Close()
	}(file)

	if _, err = file.WriteString(content); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}
	newTags := utils.GetTags(content)
	tagsToAdd, tagsToDel := utils.CalcTagsDiff(oldTags, newTags)
	err = memento.Db().Transaction(
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
				err = tx.Model(&tag).Association("Posts").Append(&post)
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
			}
			for _, tag := range tagsToDel {
				err = tx.Model(&post).Association("Tags").Delete(&tag)
				if err != nil {
					log.Errorf(err.Error())
					return err
				}
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
	defer onPostsChanged(username.(string))
	return c.NoContent(http.StatusOK)
}
func HandleGetPost(c echo.Context) error {
	id := c.QueryParam("id")
	var post model.Post
	err := memento.Db().First(&post, "id=?", id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var user model.User
	memento.Db().First(&user, "username=?", post.Username)
	var likePosts []model.Post
	err = memento.Db().
		Model(&user).
		Association("Likes").
		Find(&likePosts, "id=?", post.ID)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	pv, err := utils.PostToView(
		&post,
		utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)),
		len(likePosts) > 0)
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
	err = memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	var total int64
	if userself == username {
		err = memento.Db().
			Where("username=?", username).
			Order("created_at desc").
			Offset(page * memento.PageSize).
			Limit(memento.PageSize).
			Find(&posts).
			Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
		err = memento.Db().Model(&model.Post{}).Where("username=?", username).Count(&total).Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
	} else {
		err = memento.Db().
			Where("username=? and is_private=?", username, false).
			Order("created_at desc").Offset(page * memento.PageSize).
			Limit(memento.PageSize).
			Find(&posts).
			Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
		err = memento.Db().
			Model(&model.Post{}).
			Where("username=? and is_private=?", username, false).
			Count(&total).
			Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
	}

	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, post := range posts {
		var likePosts []model.Post
		err = memento.Db().
			Model(&user).
			Association("Likes").
			Find(&likePosts, "id=?", post.ID)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		pv, err := utils.PostToView(
			&post,
			utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)),
			len(likePosts) > 0)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(total),
	})
}

func HandlePostLike(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	postId := c.FormValue("id")
	var user model.User
	err := memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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
	var likedPost []model.Post
	err = memento.Db().
		Model(&user).
		Association("Likes").
		Find(&likedPost, "id=?", post.ID)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if len(likedPost) > 0 {
		log.Infof("liked post: %d", len(likedPost))
		return utils.RespondError(c, "already liked")
	}
	var author model.User
	err = memento.Db().First(&author, "username=?", post.Username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.Db().Transaction(
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
	err := memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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
	var likedPost model.Post
	err = memento.Db().Model(&user).Association("Likes").Find(&likedPost, "id=?", post.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "not liked yet")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	var author model.User
	err = memento.Db().First(&author, "username=?", post.Username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "post not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.Db().Transaction(
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
	username := c.Get("username").(string)
	var user model.User
	if username != "" {
		err := memento.Db().First(&user, "username=?", username).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
	}
	t := c.QueryParam("tag")
	if !strings.HasPrefix(t, "#") {
		t = "#" + t
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var tag model.Tag
	err = memento.Db().First(&tag, "name=?", t).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "tag not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	err = memento.Db().Model(&tag).Order("created_at desc").
		Offset(page*memento.PageSize).
		Limit(memento.PageSize).
		Association("Posts").
		Find(&posts, "is_private=? or username=?", false, username)
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	total := memento.Db().Model(&tag).Association("Posts").Count()
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var user model.User
		memento.Db().First(&user, "username=?", p.Username)
		var likePosts []model.Post
		err = memento.Db().
			Model(&user).
			Association("Likes").
			Find(&likePosts, "id=?", p.ID)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		pv, err := utils.PostToView(
			&p,
			utils.UserToView(&user, checkIsFollowed(username, user.Username)),
			len(likePosts) > 0)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(total),
	})
}

func HandleGetAllPosts(c echo.Context) error {
	username := c.Get("username")
	var currentUser model.User
	if username != "" {
		err := memento.Db().First(&currentUser, "username=?", username).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	err = memento.Db().
		Order("created_at desc").
		Offset(page*memento.PageSize).
		Limit(memento.PageSize).
		Find(&posts, "is_private=?", false).
		Error
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	var total int64
	err = memento.Db().Model(&model.Post{}).Where("is_private=?", false).Count(&total).Error
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var user model.User
		memento.Db().First(&user, "username=?", p.Username)
		isLiked := false
		if username != "" {
			var likePosts []model.Post
			err = memento.Db().
				Model(&currentUser).
				Association("Likes").
				Find(&likePosts, "id=?", p.ID)
			if err != nil {
				log.Errorf(err.Error())
			}
			isLiked = len(likePosts) > 0
		}
		pv, err := utils.PostToView(
			&p,
			utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)),
			isLiked)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(total),
	})
}

func HandleGetLikedPosts(c echo.Context) error {
	currentUserName := c.Get("username")
	username := c.QueryParam("username")
	var currentUser model.User
	if currentUserName != "" {
		err := memento.Db().First(&currentUser, "username=?", currentUserName).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}
	var user model.User
	err = memento.Db().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	posts := make([]model.Post, 0, memento.PageSize)
	err = memento.Db().Model(&user).
		Order("created_at desc").
		Offset(page*memento.PageSize).
		Limit(memento.PageSize).
		Association("Likes").
		Find(&posts, "is_private=? or username=?", false, currentUserName)
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	var totalLikes int64
	err = memento.Db().Model(&model.Post{}).
		Joins("JOIN user_liked_posts ON user_liked_posts.post_id = posts.id").
		Where("posts.is_private = ? OR posts.username = ?", false, currentUserName).
		Count(&totalLikes).Error
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var author model.User
		memento.Db().First(&author, "username=?", p.Username)
		isLiked := currentUserName == username
		if !isLiked && currentUserName != "" {
			var likePosts []model.Post
			err = memento.Db().
				Model(&currentUser).
				Association("Likes").
				Find(&likePosts, "id=?", p.ID)
			if err != nil {
				log.Errorf(err.Error())
			}
			isLiked = len(likePosts) > 0
		}
		pv, err := utils.PostToView(
			&p,
			utils.UserToView(&author, checkIsFollowed(c.Get("username").(string), author.Username)),
			isLiked)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(totalLikes),
	})
}

func HandleGetTags(c echo.Context) error {
	var tags []model.Tag
	t := c.QueryParam("type")
	if t == "all" {
		err := memento.Db().Find(&tags).Error
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
		tags1 := make([]model.Tag, 0, len(tags))
		for _, t := range tags {
			count := memento.Db().Model(&t).Association("Posts").Count()
			if count != 0 {
				tags1 = append(tags1, t)
			}
		}
		tags = tags1
	} else {
		username := c.Get("username")
		if username == "" {
			return utils.RespondUnauthorized(c)
		}
		var user model.User
		err := memento.Db().First(&user, "username=?", username).Error
		if err != nil {
			return utils.RespondError(c, "username not exists")
		}
		var posts []model.Post
		err = memento.Db().Preload("Tags").Model(&user).Association("Posts").Find(&posts)
		if err != nil {
			return utils.RespondError(c, "unknown query error")
		}
		tagMap := make(map[string]bool)
		for _, p := range posts {
			for _, t := range p.Tags {
				tagMap[t.Name] = true
			}
		}
		for k := range tagMap {
			tags = append(tags, model.Tag{Name: k})
		}
	}
	tagsList := make([]string, len(tags))
	for i, t := range tags {
		tagsList[i] = t.Name
	}
	return c.JSON(http.StatusOK, tagsList)
}

func HandleGetFollowingPosts(c echo.Context) error {
	username := c.Get("username").(string)
	var user model.User
	err := memento.Db().Preload("Follows").First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "username not exists")
	}
	page, err := strconv.Atoi(c.QueryParam("page"))
	if err != nil {
		return utils.RespondError(c, "invalid page")
	}

	var followedUsernames []string
	for _, follow := range user.Follows {
		followedUsernames = append(followedUsernames, follow.Username)
	}
	// Get the posts of followed users
	var posts []model.Post
	err = memento.Db().
		Limit(memento.PageSize).
		Offset(memento.PageSize*page).
		Where("username IN ?", followedUsernames).
		Find(&posts).
		Error
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	var total int64
	err = memento.Db().
		Model(&model.Post{}).
		Where("username IN ?", followedUsernames).
		Count(&total).
		Error
	if err != nil {
		return utils.RespondError(c, "unknown query error")
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for _, p := range posts {
		var author model.User
		memento.Db().First(&author, "username=?", p.Username)
		isLiked := false
		if username != "" {
			var likePosts []model.Post
			err = memento.Db().
				Model(&user).
				Association("Likes").
				Find(&likePosts, "id=?", p.ID)
			if err != nil {
				log.Errorf(err.Error())
			}
			isLiked = len(likePosts) > 0
		}
		pv, err := utils.PostToView(&p, utils.UserToView(&author, true), isLiked)
		if err != nil {
			log.Errorf(err.Error())
			continue
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(total),
	})
}

func onPostsChanged(username string) {
	GenerateSiteMap()
	_, err := cacheRss(username)
	if err != nil {
		log.Errorf("Error caching RSS: %s\n", err.Error())
	}
}
