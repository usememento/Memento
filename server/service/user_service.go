package service

import (
	"Memento/server"
	"Memento/server/model"
	"Memento/server/utils"
	"errors"
	"fmt"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"io"
	"net/http"
	"os"
	"path"
	"strconv"
	"time"
)

func HandleUserCreate(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	hashedPassword := utils.Md5string(password)
	err := server.Memento.DbConn.Create(&model.User{
		Username:     username,
		PasswordHash: hashedPassword,
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
		return c.String(http.StatusBadRequest, "unknown insertion error")
	}
	return c.String(http.StatusOK, fmt.Sprintf("user %s created", username))
}

func HandleUserDelete(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return c.String(http.StatusBadRequest, "incorrect Username or Password")
	}
	server.Memento.DbConn.Delete(&user)
	return c.String(http.StatusOK, "delete succeeded")
}

func HandleUserEdit(c echo.Context) error {
	form, err := c.FormParams()
	//fmt.Println(form)
	username := c.FormValue("username")
	nickname := form["nickname"]
	bio := form["bio"]

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
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	if len(nickname) == 1 {
		user.Nickname = nickname[0]
	}
	if len(bio) == 1 {
		user.Bio = bio[0]
	}
	if hasAvatar {
		// Source
		file, err := avatar.Open()
		if err != nil {
			return c.String(http.StatusBadRequest, "form file open error")
		}
		defer file.Close()
		ext := path.Ext(avatar.Filename)
		filename := utils.Md5string(strconv.FormatInt(time.Now().UnixMilli(), 10)) + ext
		// Destination
		filepath := path.Join(server.Memento.Config.ServerConfig.FilePath, "avatar", filename)
		dst, err := os.Create(filepath)
		if err != nil {
			return c.String(http.StatusBadRequest, "os file open error")
		}
		defer dst.Close()
		// Copy
		if _, err = io.Copy(dst, file); err != nil {
			return c.String(http.StatusBadRequest, "data copy error")
		}
		user.AvatarUrl = filename
	}
	server.Memento.DbConn.Save(&user)
	//fmt.Println(user)
	return c.String(http.StatusOK, "edit succeeded")
}

func HandleUserGetInfo(c echo.Context) error {
	username := c.QueryParam("username")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	return c.JSON(http.StatusOK, struct {
		Username     string
		Nickname     string
		Bio          string
		TotalLiked   int64
		TotalComment int64
		TotalPosts   int64
		RegisteredAt time.Time
	}{
		Username:     user.Username,
		Nickname:     user.Nickname,
		Bio:          user.Bio,
		RegisteredAt: user.RegisteredAt,
		TotalLiked:   user.TotalLiked,
		TotalComment: user.TotalComment,
		TotalPosts:   user.TotalPosts})
}

func HandleUserGetAvatar(c echo.Context) error {
	username := c.QueryParam("username")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	return c.File(path.Join(server.Memento.Config.FilePath, "avatar", user.AvatarUrl))
}

func HandleUserLogin(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return c.String(http.StatusBadRequest, "incorrect Username or Password")
	}
	return c.String(http.StatusOK, "login succeeded")
}

func HandleUserChangePwd(c echo.Context) error {
	username := c.FormValue("username")
	oldPassword := c.FormValue("oldPassword")
	newPassword := c.FormValue("newPassword")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	if utils.Md5string(oldPassword) != user.PasswordHash {
		return c.String(http.StatusBadRequest, "incorrect old password")
	}
	server.Memento.DbConn.Model(&user).Update("password_hash", utils.Md5string(newPassword))
	return c.String(http.StatusOK, "password changed")
}
