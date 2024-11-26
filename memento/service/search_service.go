package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"net/http"
	"strconv"
	"strings"
)

func HandleUserSearch(c echo.Context) error {
	keyword := c.QueryParam("keyword")
	pageStr := c.QueryParam("page")
	page, err := strconv.Atoi(pageStr)
	if err != nil {
		return utils.RespondError(c, "invalid page number")
	}
	if keyword == "" {
		return utils.RespondError(c, "invalid keyword")
	}
	var users []model.User
	var total int64
	if strings.HasPrefix(keyword, "@") {
		err = memento.Db().
			Limit(memento.PageSize).
			Offset(page*memento.PageSize).
			Where("username LIKE ?", keyword[1:]+"%").
			Find(&users).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
		err = memento.Db().
			Model(&model.User{}).
			Where("username LIKE ?", "%"+keyword[1:]+"%").
			Count(&total).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
	} else {
		err = memento.Db().
			Limit(memento.PageSize).
			Offset(page*memento.PageSize).
			Where("username LIKE ? OR nickname LIKE ? OR bio LIKE ?", "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%").
			Find(&users).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
		err = memento.Db().
			Model(&model.User{}).
			Where("username LIKE ? OR nickname LIKE ? OR bio LIKE ?", "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%").
			Count(&total).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
	}
	result := make([]model.UserViewModel, 0, memento.PageSize)
	for _, user := range users {
		result = append(result, *utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)))
	}
	return c.JSON(http.StatusOK, echo.Map{
		"users":   result,
		"maxPage": utils.MaxPage(total),
	})
}

func HandlePostSearch(c echo.Context) error {
	username := c.Get("username")
	keywords := c.QueryParam("keyword")
	pageStr := c.QueryParam("page")
	page, err := strconv.Atoi(pageStr)
	if err != nil {
		return utils.RespondError(c, "invalid page number")
	}
	if keywords == "" {
		return utils.RespondError(c, "invalid keyword")
	}
	keywordsList := strings.Split(keywords, " ")
	var posts []model.Post
	isFirst := true
	for _, keyword := range keywordsList {
		if keyword == "" {
			continue
		}
		keyword = strings.TrimSpace(keyword)
		result, err := doSearch(keyword)
		log.Infof("search result: %d", len(result))
		if err != nil {
			log.Errorf("search failed: %v", err)
			return utils.RespondInternalError(c, "search failed")
		}
		if isFirst {
			isFirst = false
			posts = result
		} else {
			newResult := make([]model.Post, 0, len(posts))
			for _, post := range posts {
				for _, newPost := range result {
					if post.ID == newPost.ID {
						newResult = append(newResult, post)
						break
					}
				}
			}
			posts = newResult
		}
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	for index, post := range posts {
		if index < page*memento.PageSize {
			continue
		}
		if index >= (page+1)*memento.PageSize {
			break
		}
		var author model.User
		err = memento.Db().
			Where("username=?", post.Username).
			First(&author).
			Error
		if err != nil {
			log.Errorf("search failed: %v", err)
			return utils.RespondInternalError(c, "search failed")
		}
		isLiked := false
		if username != "" {
			var user model.User
			err = memento.Db().
				Where("username=?", username).
				First(&user).
				Error
			if err != nil {
				log.Errorf("search failed: %v", err)
				return utils.RespondInternalError(c, "search failed")
			}
			var likedPosts []model.Post
			err = memento.Db().
				Model(&user).
				Association("Likes").
				Find(&likedPosts, "id=?", post.ID)
			if err != nil {
				log.Errorf("search failed: %v", err)
				return utils.RespondInternalError(c, "search failed")
			}
			isLiked = len(likedPosts) > 0
		}
		postView, err := utils.PostToView(
			&post,
			utils.UserToView(
				&author,
				checkIsFollowed(username.(string), author.Username)),
			isLiked)
		if err != nil {
			log.Errorf("search failed: %v", err)
			return utils.RespondInternalError(c, "search failed")
		}
		result = append(result, *postView)
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(int64(len(posts))),
	})
}

func doSearch(keyword string) ([]model.Post, error) {
	if strings.HasPrefix(keyword, "#") {
		// search tag
		var posts []model.Post
		var tag model.Tag
		err := memento.Db().
			Where("name=?", keyword).
			First(&tag).
			Error
		if err != nil {
			return make([]model.Post, 0), nil
		}
		err = memento.Db().
			Model(&tag).
			Association("Posts").
			Find(&posts)
		if err != nil {
			return make([]model.Post, 0), nil
		}
		return posts, nil
	} else if strings.HasPrefix(keyword, "@") {
		// search user
		var posts []model.Post
		var user model.User
		err := memento.Db().
			Where("username=?", keyword[1:]).
			First(&user).
			Error
		if err != nil {
			return make([]model.Post, 0), nil
		}
		err = memento.Db().
			Model(&user).
			Association("Posts").
			Find(&posts)
		if err != nil {
			return make([]model.Post, 0), nil
		}
		return posts, nil
	} else {
		// search post
		sr, err := memento.SearchPost(keyword)
		if err != nil {
			return make([]model.Post, 0), err
		}
		posts := make([]model.Post, 0, len(sr.Hits))
		for _, hit := range sr.Hits {
			var post model.Post
			memento.Db().First(&post, "id=?", hit.Fields["ID"])
			posts = append(posts, post)
		}
		return posts, nil
	}
}
