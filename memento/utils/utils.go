package utils

import (
	"Memento/memento/model"
	"crypto/md5"
	"encoding/hex"
	"net/http"
	"os"
	"strings"

	"github.com/labstack/echo/v4"
)

const pageSize = 20

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

func GetTags(content string) []string {
	content = strings.ReplaceAll(content, "\r", "")
	lines := strings.Split(content, "\n")
	result := make([]string, 0)

	isCode := false

	for _, l := range lines {
		if strings.HasPrefix(l, "```") || strings.HasPrefix(l, "~~~") {
			isCode = !isCode
		}
		if isCode {
			continue
		}
		blocks := strings.Split(l, " ")

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
	tagToAdd = make([]string, 0)
	tagToDel = make([]string, 0)

	for _, t := range newTags {
		if !Contains(oldTags, t) {
			tagToAdd = append(tagToAdd, t)
		}
	}

	for _, t := range oldTags {
		if !Contains(newTags, t) {
			tagToDel = append(tagToDel, t)
		}
	}

	return tagToAdd, tagToDel
}

func Contains(array []string, value string) bool {
	for _, t := range array {
		if t == value {
			return true
		}
	}
	return false
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
	avatarPath := user.AvatarUrl
	avatar := "user.png"
	if avatarPath != "" {
		for i := len(avatarPath) - 1; i >= 0; i-- {
			if avatarPath[i] == '/' || avatarPath[i] == '\\' {
				avatar = avatarPath[i+1:]
				break
			}
		}
	}
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
		Avatar:        avatar,
		IsFollowed:    isFollowed,
		IsAdmin:       user.IsAdmin,
	}
}

func MaxPage(total int64) int64 {
	if total%pageSize == 0 {
		return max(total/pageSize-1, 0)
	}
	return total/pageSize + total%pageSize - 1
}
