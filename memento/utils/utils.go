package utils

import (
	"Memento/memento/model"
	"crypto/md5"
	"encoding/hex"
	"github.com/labstack/echo/v4"
	"net/http"
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
