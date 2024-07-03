package utils

import (
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

func RespondError(c echo.Context, msg string) error {
	return c.JSON(http.StatusBadRequest,
		map[string]string{
			"message": msg,
		})
}

func RespondOk(c echo.Context, msg string) error {
	return c.JSON(http.StatusOK,
		map[string]string{
			"message": msg,
		})
}
