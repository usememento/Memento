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
)

func HandleUserSearch(c echo.Context) error {
	keywords := c.QueryParam("keyword")
	if keywords == "" {
		return utils.RespondError(c, "invalid keyword")
	}

	return nil
}
func HandlePostSearch(c echo.Context) error {
	username := c.Get("username")
	keywords := c.QueryParam("keyword")
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
	memento.GetDbConnection().First(&user, "username=?", username)
	for _, hit := range sr.Hits {
		var post model.Post
		memento.GetDbConnection().First(&post, "id=?", hit.Fields["ID"])
		fmt.Println(hit.Fields["ID"])
		var likePosts []model.Post
		memento.GetDbConnection().Model(&user).Association("Likes").Find(&likePosts, "id=?", post.ID)
		pv, err := utils.PostToView(&post, utils.UserToView(&user, checkIsFollowed(c.Get("username").(string), user.Username)), len(likePosts) > 0)
		if err != nil {
			return utils.RespondError(c, "os open file error")
		}
		result = append(result, *pv)
	}
	return c.JSON(http.StatusOK, result)
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
