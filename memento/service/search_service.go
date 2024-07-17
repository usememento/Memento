package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"fmt"
	"github.com/blevesearch/bleve/v2"
	"github.com/labstack/echo/v4"
	"net/http"
	"path"
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
		err = memento.GetDbConnection().
			Limit(memento.PageSize).
			Offset(page*memento.PageSize).
			Where("username LIKE ?", keyword[1:]+"%").
			Find(&users).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
		err = memento.GetDbConnection().
			Model(&model.User{}).
			Where("username LIKE ?", "%"+keyword[1:]+"%").
			Count(&total).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
	} else {
		err = memento.GetDbConnection().
			Limit(memento.PageSize).
			Offset(page*memento.PageSize).
			Where("username LIKE ? OR nickname LIKE ? OR bio LIKE ?", "%"+keyword+"%", "%"+keyword+"%", "%"+keyword+"%").
			Find(&users).
			Error
		if err != nil {
			return utils.RespondInternalError(c, "search failed")
		}
		err = memento.GetDbConnection().
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
	sr, err := memento.SearchPost(keywords)
	fmt.Println(sr)
	if err != nil {
		return utils.RespondInternalError(c, "search failed")
	}
	result := make([]model.PostViewModel, 0, memento.PageSize)
	var user model.User
	if username != "" {
		memento.GetDbConnection().First(&user, "username=?", username)
	}
	for index, hit := range sr.Hits {
		for index < page*memento.PageSize {
			continue
		}
		var post model.Post
		memento.GetDbConnection().First(&post, "id=?", hit.Fields["ID"])
		if post.IsPrivate && post.Username != username {
			continue
		}
		fmt.Println(hit.Fields["ID"])
		var likePosts []model.Post
		if username != "" {
			memento.GetDbConnection().Model(&user).Association("Likes").Find(&likePosts, "id=?", post.ID)
		}
		pv, err := utils.PostToView(&post, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
		if err != nil {
			return utils.RespondError(c, "os open file error")
		}
		result = append(result, *pv)
		if len(result) == memento.PageSize {
			break
		}
	}
	return c.JSON(http.StatusOK, echo.Map{
		"posts":   result,
		"maxPage": utils.MaxPage(int64(len(sr.Hits))),
	})
}

func search() {
	// open a new index
	mapping := bleve.NewIndexMapping()
	index, err := bleve.New(path.Join(memento.GetBasePath(), "inverted_index.bleve"), mapping)
	if err != nil {
		fmt.Println(err)
		return
	}

	data := struct {
		Name string
	}{
		Name: "text",
	}
	// index some data
	index.Index("id", data)

	// search for some text
	query := bleve.NewMatchQuery("text hello")
	search := bleve.NewSearchRequest(query)
	searchResults, err := index.Search(search)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(searchResults)
}
