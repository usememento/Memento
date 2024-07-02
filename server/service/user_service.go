package service

import (
	"Memento/server"
	"Memento/server/model"
	"crypto/md5"
	"encoding/hex"
	"errors"
	"fmt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"io"
	"net/http"
	"os"
	"path"
	"time"
)

func HandleUserCreate(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	hasher := md5.New()
	hasher.Write([]byte(password))
	err := server.Memento.DbConn.Create(&model.User{
		Username:     username,
		PasswordHash: hex.EncodeToString(hasher.Sum(nil)),
		AvatarUrl:    "",
		Nickname:     "",
		Bio:          "",
		TotalLiked:   0,
		TotalComment: 0,
		TotalPosts:   0,
		RegisteredAt: time.Now(),
	}).Error
	if err != nil {
		// Check if the error is due to a unique constraint violation
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s already exists", username))
		}
	}
	return c.String(http.StatusOK, fmt.Sprintf("user %s created", username))
}

func HandleUserDelete(c echo.Context) error {
	return nil
}

func HandleUserEdit(c echo.Context) error {
	username := c.FormValue("username")
	nickname := c.FormValue("nickname")
	bio := c.FormValue("bio")
	hasAvatar := false
	avatar, err := c.FormFile("avatar")
	if err == nil {
		hasAvatar = true
	}
	var user model.User
	err = server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
	}
	user.Nickname = nickname
	user.Bio = bio
	if hasAvatar {
		// Source
		file, err := avatar.Open()
		if err != nil {
			return err
		}
		defer file.Close()
		// Destination
		path := path.Join(server.Memento.Config.ServerConfig.FilePath, avatar.Filename)
		dst, err := os.Create(path)
		if err != nil {
			return err
		}
		defer dst.Close()
		// Copy
		if _, err = io.Copy(dst, file); err != nil {
			return err
		}
		user.AvatarUrl = path
	}
	server.Memento.DbConn.Model(&user).Updates(&user)
	return c.String(http.StatusOK, "edit succeeded")
}

func HandleUserGet(c echo.Context) error {
	return nil
}

func HandleUserLogin(c echo.Context) error {
	return nil
}

func HandleUserChangePwd(c echo.Context) error {
	return nil
}
