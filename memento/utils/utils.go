package utils

import (
	"Memento/memento/model"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"github.com/labstack/echo/v4"
	"net/http"
	"os"
	"regexp"
	"strings"
)

func Md5string(s string) string {
	hasher := md5.New()
	hasher.Write([]byte(s))
	return hex.EncodeToString(hasher.Sum(nil))
}

func RespondError(c echo.Context, msg interface{}) error {
	return c.JSON(http.StatusBadRequest,
		map[string]interface{}{
			"message": msg,
		})
}

func RespondOk(c echo.Context, msg interface{}) error {
	return c.JSON(http.StatusOK,
		map[string]interface{}{
			"message": msg,
		})
}

func GetPostIndex(posts []model.Post, post model.Post) int {
	for i, p := range posts {
		if post.ID == p.ID {
			return i
		}
	}
	return -1
}

func GetTags(content string) []string {
	pattern := `#\w+ `

	re, err := regexp.Compile(pattern)
	if err != nil {
		fmt.Println("Error compiling regex:", err)
		return nil
	}
	matches := re.FindAllString(content, -1)
	var result []string
	for _, m := range matches {
		result = append(result, strings.TrimSpace(m))
	}
	return result
}

func CalcTagsDiff(oldTags []string, newTags []string) (tagToAdd []string, tagToDel []string) {
	oldTagSet := make(map[string]struct{})
	for _, tag := range oldTags {
		oldTagSet[tag] = struct{}{}
	}

	newTagSet := make(map[string]struct{})
	for _, tagName := range newTags {
		newTagSet[tagName] = struct{}{}
	}
	var tagsToAdd []string
	var tagsToDel []string
	for _, t := range newTags {
		if _, found := oldTagSet[t]; !found {
			tagsToAdd = append(tagsToAdd, t)
		}
	}
	for _, t := range oldTags {
		if _, found := newTagSet[t]; !found {
			tagsToDel = append(tagsToDel, t)
		}
	}
	return tagToAdd, tagToDel
}

func PostToView(post *model.Post) (*model.PostViewModel, error) {
	content, err := os.ReadFile(post.ContentUrl)
	if err != nil {
		return nil, err
	}
	return &model.PostViewModel{
		PostID:    post.ID,
		Username:  post.Username,
		Liked:     post.Liked,
		CreatedAt: post.CreatedAt,
		EditedAt:  post.EditedAt,
		Content:   string(content),
	}, nil
}

func CommentToView(comment *model.Comment) *model.CommentViewModel {
	return &model.CommentViewModel{
		CommentID: comment.ID,
		PostID:    comment.PostID,
		Username:  comment.Username,
		CreatedAt: comment.CreatedAt,
		EditedAt:  comment.EditedAt,
		Content:   comment.Content,
		Liked:     0,
	}
}

func UserToView(user *model.User) *model.UserViewModel {
	return &model.UserViewModel{
		Username:     user.Username,
		Nickname:     user.Nickname,
		Bio:          user.Bio,
		RegisteredAt: user.RegisteredAt,
		TotalLiked:   user.TotalLiked,
		TotalComment: user.TotalComment,
		TotalPosts:   user.TotalPosts,
		AvatarUrl:    user.AvatarUrl,
	}
}
