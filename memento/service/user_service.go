package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"fmt"
	echoserver "github.com/dasjott/oauth2-echo-server"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
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
	err := memento.GetDbConnection().Create(&model.User{
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
			return utils.RespondError(c, fmt.Sprintf("username %s already exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}
	return utils.RespondOk(c, fmt.Sprintf("user %s created", username))
}

func HandleUserDelete(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return utils.RespondError(c, "incorrect Username or Password")
	}
	memento.GetDbConnection().Delete(&user)
	return utils.RespondOk(c, "delete succeeded")
}

func HandleUserEdit(c echo.Context) error {
	form, err := c.FormParams()
	username := c.FormValue("username")
	nickname := form["nickname"]
	bio := form["bio"]

	hasAvatar := false
	avatar, err := c.FormFile("avatar")
	if err == nil {
		hasAvatar = true
	}
	var user model.User
	err = memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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
			log.Errorf(err.Error())
			return utils.RespondError(c, "form file open error")
		}
		defer file.Close()
		ext := path.Ext(avatar.Filename)
		filename := utils.Md5string(strconv.FormatInt(time.Now().UnixMilli(), 10)) + ext
		// Destination
		filepath := path.Join(memento.GetAvatarPath(), filename)
		dst, err := os.Create(filepath)
		if err != nil {
			log.Errorf(err.Error())
			return utils.RespondError(c, "os file open error")
		}
		defer dst.Close()
		// Copy
		if _, err = io.Copy(dst, file); err != nil {
			log.Errorf(err.Error())
			return utils.RespondError(c, "data copy error")
		}
		user.AvatarUrl = filepath
	}
	if err := memento.GetDbConnection().Save(&user).Error; err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown save error")
	}
	return utils.RespondOk(c, "edit succeeded")
}

func HandleUserGetInfo(c echo.Context) error {
	username := c.QueryParam("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
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
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	return c.File(user.AvatarUrl)
}

func HandleLogin(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return utils.RespondError(c, "incorrect Username or Password")
	}
	return echoserver.HandleTokenRequest(c)
}

func HandleUserChangePwd(c echo.Context) error {
	username := c.FormValue("username")
	oldPassword := c.FormValue("oldPassword")
	newPassword := c.FormValue("newPassword")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, fmt.Sprintf("username %s not exists", username))
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if utils.Md5string(oldPassword) != user.PasswordHash {
		return utils.RespondError(c, "incorrect old password")
	}
	if err := memento.GetDbConnection().Model(&user).Update("password_hash", utils.Md5string(newPassword)).Error; err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown update error")
	}
	return utils.RespondOk(c, "password changed")
}
