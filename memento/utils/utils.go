package utils

import (
	"Memento/memento/model"
	"crypto/md5"
	"encoding/hex"
	"github.com/labstack/echo/v4"
	"net/http"
	"os"
	"strings"
)

func Md5string(s string) string {
	hasher := md5.New()
	hasher.Write([]byte(s))
	return hex.EncodeToString(hasher.Sum(nil))
}

func RespondError(c echo.Context, msg interface{}) error {
	return c.JSON(http.StatusBadRequest,
		echo.Map{
			"message": msg,
		})
}

func RespondOk(c echo.Context, msg interface{}) error {
	return c.JSON(http.StatusOK,
		echo.Map{
			"message": msg,
		})
}

func RespondUnauthorized(c echo.Context) error {
	return c.JSON(http.StatusUnauthorized,
		echo.Map{
			"message": "invalid token",
		})
}
func RespondInternalError(c echo.Context, msg interface{}) error {
	return c.JSON(http.StatusInternalServerError,
		echo.Map{
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
	lines := strings.Split(content, "\r\n")
	var result []string

	for _, l := range lines {
		blocks := strings.Split(l, " ")
		//log.Infof("%q\n", blocks)

		for _, b := range blocks {
			if len(b) > 1 && len(b) <= 21 && b[0] == '#' && b[1] != '#' {
				result = append(result, b)
			}
		}
	}

	//log.Infof("%q\n", result)
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

func PostToView(post *model.Post, user *model.UserViewModel, liked bool) (*model.PostViewModel, error) {
	content, err := os.ReadFile(post.ContentUrl)
	if err != nil {
		return nil, err
	}
	return &model.PostViewModel{
		IsLiked:      liked,
		IsPrivate:    post.IsPrivate,
		PostID:       post.ID,
		User:         *user,
		TotalLiked:   post.TotalLiked,
		TotalComment: post.TotalComment,
		CreatedAt:    post.CreatedAt,
		EditedAt:     post.EditedAt,
		Content:      string(content),
	}, nil
}

func CommentToView(comment *model.Comment, user *model.UserViewModel, isLiked bool) *model.CommentViewModel {
	return &model.CommentViewModel{
		CommentID: comment.ID,
		PostID:    comment.PostID,
		User:      *user,
		CreatedAt: comment.CreatedAt,
		EditedAt:  comment.EditedAt,
		Content:   comment.Content,
		Liked:     comment.Liked,
		IsLiked:   isLiked,
	}
}

func UserToView(user *model.User, isFollowed bool) *model.UserViewModel {
	return &model.UserViewModel{
		Username:      user.Username,
		Nickname:      user.Nickname,
		Bio:           user.Bio,
		RegisteredAt:  user.RegisteredAt,
		TotalLiked:    user.TotalLiked,
		TotalComment:  user.TotalComment,
		TotalFiles:    user.TotalFiles,
		TotalFollows:  user.TotalFollows,
		TotalFollower: user.TotalFollower,
		TotalPosts:    user.TotalPosts,
		AvatarUrl:     user.AvatarUrl,
		IsFollowed:    isFollowed,
	}
}
