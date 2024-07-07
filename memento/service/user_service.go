package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"context"
	"errors"
	"github.com/go-oauth2/oauth2/v4/server"
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

func HandleUserCreateWrapper(c echo.Context, s *server.Server) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	hashedPassword := utils.Md5string(password)
	user := model.User{
		Username:     username,
		PasswordHash: hashedPassword,
		AvatarUrl:    "",
		Nickname:     username,
		Bio:          "",
		TotalLiked:   0,
		TotalComment: 0,
		TotalPosts:   0,
		RegisteredAt: time.Now(),
	}
	err := memento.GetDbConnection().Create(&user).Error
	if err != nil {
		// Check if the error is due to a unique constraint violation
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			// Username already exists
			return utils.RespondError(c, "username already exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown insertion error")
	}

	gt, tgr, err := s.ValidationTokenRequest(c.Request())
	if err != nil {
		return utils.RespondError(c, err.Error())
	}

	ti, err := s.GetAccessToken(c.Request().Context(), gt, tgr)
	if err != nil {
		return utils.RespondError(c, err.Error())
	}
	return c.JSON(http.StatusOK, echo.Map{
		"token": s.GetTokenData(ti),
		"user":  utils.UserToView(&user),
	})
}
func HandleUserLoginWrapper(c echo.Context, s *server.Server) error {
	username := c.FormValue("username")
	password := c.FormValue("password")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return utils.RespondError(c, "incorrect password")
	}

	gt, tgr, err := s.ValidationTokenRequest(c.Request())
	if err != nil {
		return utils.RespondError(c, err.Error())
	}

	ti, err := s.GetAccessToken(c.Request().Context(), gt, tgr)
	if err != nil {
		return utils.RespondError(c, err.Error())
	}
	return c.JSON(http.StatusOK, echo.Map{
		"token": s.GetTokenData(ti),
		"user":  utils.UserToView(&user),
	})
}
func HandleUserRefreshToken(c echo.Context, s *server.Server) error {
	gt, tgr, err := s.ValidationTokenRequest(c.Request())
	if err != nil {
		return utils.RespondError(c, err.Error())
	}

	ti, err := s.GetAccessToken(c.Request().Context(), gt, tgr)
	if err != nil {
		return utils.RespondError(c, err.Error())
	}
	return c.JSON(http.StatusOK, echo.Map{
		"token": s.GetTokenData(ti),
	})
}
func HandleUserDelete(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	password := c.FormValue("password")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if utils.Md5string(password) != user.PasswordHash {
		return utils.RespondError(c, "incorrect username or password")
	}
	memento.GetDbConnection().Delete(&user)
	return c.NoContent(http.StatusOK)
}

func HandleUserEdit(c echo.Context) error {
	form, err := c.FormParams()
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	nickname := form["nickname"]
	bio := form["bio"]
	hasAvatar := true
	avatar, err := c.FormFile("avatar")
	if err != nil {
		hasAvatar = false
	}
	var user model.User
	err = memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
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
		dst, err := os.OpenFile(filepath, os.O_CREATE|os.O_RDWR, 0777)
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
		if user.AvatarUrl != "" {
			err := os.Remove(user.AvatarUrl)
			log.Errorf(err.Error())
		}
		user.AvatarUrl = filepath
	}
	if err := memento.GetDbConnection().Save(&user).Error; err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown save error")
	}
	return c.NoContent(http.StatusOK)
}

func HandleGetUser(c echo.Context) error {
	username := c.QueryParam("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	return c.JSON(http.StatusOK, utils.UserToView(&user))
}

func PasswordAuthorizationHandler(ctx context.Context, clientID, username, password string) (userID string, err error) {
	var user model.User
	//log.Debugf("PasswordAuthorizationHandler: %s\n", username)
	err = memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", err
		}
		log.Errorf(err.Error())
		return "", err
	}
	if utils.Md5string(password) != user.PasswordHash {
		return "", err
	}
	return username, nil
}
func HandleUserChangePwd(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	oldPassword := c.FormValue("oldPassword")
	newPassword := c.FormValue("newPassword")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
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
	return c.NoContent(http.StatusOK)
}

func HandleUserHeatMap(c echo.Context) error {
	username := c.FormValue("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	sixMonthsAgo := time.Now().AddDate(0, -6, 0)
	heatmap := make(map[string]int)
	var posts []model.Post
	err = memento.GetDbConnection().Model(&user).Association("Posts").Find(&posts)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	memos := len(posts)
	var likes int64
	likes = 0
	for _, p := range posts {
		likes += p.TotalLiked
		if p.EditedAt.Compare(sixMonthsAgo) < 0 {
			continue
		}
		heatmap[p.EditedAt.Format("2006-01-02")] += 1
	}
	return c.JSON(http.StatusOK, echo.Map{
		"memos": memos,
		"likes": likes,
		"map":   heatmap,
	})
}

func HandleUserFollow(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	foUsername := c.FormValue("followee")
	var user, followee model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().First(&followee, "username=?", foUsername).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Follows").Append(&followee)
			if err != nil {
				return err
			}
			err = tx.Model(&followee).Association("Followers").Append(&user)
			if err != nil {
				return err
			}
			followee.TotalFollower += 1
			user.TotalFollows += 1
			tx.Save(&user)
			tx.Save(&followee)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}
func HandleUserUnfollow(c echo.Context) error {
	username := c.Get("username")
	if username == "" {
		return utils.RespondUnauthorized(c)
	}
	foUsername := c.FormValue("followee")
	var user, followee model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().First(&followee, "username=?", foUsername).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	err = memento.GetDbConnection().Transaction(
		func(tx *gorm.DB) error {
			err := tx.Model(&user).Association("Follows").Delete(&followee)
			if err != nil {
				return err
			}
			err = tx.Model(&followee).Association("Followers").Delete(&user)
			if err != nil {
				return err
			}
			followee.TotalFollower -= 1
			user.TotalFollows -= 1
			tx.Save(&user)
			tx.Save(&followee)
			return nil
		})
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	return c.NoContent(http.StatusOK)
}
func HandlerGetUserFollower(c echo.Context) error {
	return nil
}

func HandlerGetUserFollowing(c echo.Context) error {
	return nil
}
