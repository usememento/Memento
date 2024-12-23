package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/query"
	"Memento/memento/utils"
	"errors"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"gorm.io/gorm"
	"net/http"
	"strings"
	"time"
	"unicode"
)

func HandleLogin(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")

	user, err := query.User.Where(query.User.Username.Eq(username)).First()
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return utils.RespondError(c, "username not exists")
		}
		log.Errorf(err.Error())
		return utils.RespondError(c, "unknown query error")
	}
	if user.LockUntil.After(time.Now()) {
		return utils.RespondError(c, "Too many login attempts, please try again later")
	}
	if utils.Md5string(password) != user.PasswordHash {
		user.PasswordRetry += 1
		if user.PasswordRetry >= 5 {
			log.Infof("User %s has been locked due to too many login attempts", user.Username)
			user.LockUntil = time.Now().Add(time.Minute * 5)
			user.PasswordRetry = 0
		}
		err = query.User.Save(user)
		if err != nil {
			log.Errorf(err.Error())
			return utils.RespondError(c, "unknown update error")
		}
		return utils.RespondError(c, "incorrect password")
	}

	return authOk(c, user)
}

func HandleCreate(c echo.Context) error {
	if !memento.GetConfig().EnableRegister {
		return utils.RespondError(c, "Registration Disabled")
	}
	username := c.FormValue("username")
	captchaToken := c.FormValue("captchaToken")
	if !VerifyCaptchaToken(captchaToken) {
		return utils.RespondError(c, "Invalid Captcha")
	}
	if !verifyUsername(username) {
		return utils.RespondError(c, "Invalid Username")
	}
	password := c.FormValue("password")
	if !verifyPassword(password) {
		return utils.RespondError(c, "Invalid Password")
	}
	hashedPassword := utils.Md5string(password)
	totalUsers, err := query.User.Count()
	if err != nil {
		totalUsers = 0
	}
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
		IsAdmin:      totalUsers == 0,
	}
	err = query.User.Create(&user)
	if err != nil {
		// Check if the error is due to a unique constraint violation
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			// Username already exists
			return utils.RespondError(c, "username already exists")
		}
		log.Errorf(err.Error())
		return utils.RespondInternalError(c, "unknown insertion error")
	}
	return authOk(c, &user)
}
func verifyUsername(username string) bool {
	if len(username) < 4 || len(username) > 20 {
		return false
	}
	notAllowedChars := []string{" ", "\t", "\n", "\r", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"}
	for _, char := range notAllowedChars {
		if strings.Contains(username, char) {
			return false
		}
	}
	return true
}

func verifyPassword(password string) bool {
	if len(password) < 6 || len(password) > 30 {
		return false
	}
	hasDigit := false
	hasLetter := false
	for _, r := range password {
		if r > unicode.MaxASCII {
			return false
		}
		if unicode.IsDigit(r) {
			hasDigit = true
		}
		if unicode.IsLetter(r) {
			hasLetter = true
		}
	}
	return hasDigit && hasLetter
}

func authOk(c echo.Context, user *model.User) error {
	claims := &model.JwtUserClaims{
		Username: user.Username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour * 24 * 3)),
		},
	}
	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Generate encoded token and send it as response.
	t, err := token.SignedString([]byte(memento.GetConfig().AccessTokenSigningKey))
	refreshToken, err := generateRefreshToken(user)
	if err != nil {
		return err
	}
	return c.JSON(http.StatusOK, echo.Map{
		"accessToken":  t,
		"refreshToken": refreshToken,
		"isAdmin":      user.IsAdmin,
		"expiredAt":    claims.ExpiresAt.Format(time.RFC3339),
		"user":         utils.UserToView(user, false),
	})
}

func generateRefreshToken(user *model.User) (string, error) {
	claims := &model.JwtUserClaims{
		Username: user.Username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour * 24 * 7)),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(memento.GetConfig().RefreshTokenSigningKey))
}

func HandleRefreshToken(c echo.Context) error {
	refreshToken := c.FormValue("refreshToken")
	token, err := jwt.ParseWithClaims(refreshToken, &model.JwtUserClaims{}, func(token *jwt.Token) (interface{}, error) {
		return []byte(memento.GetConfig().RefreshTokenSigningKey), nil
	})
	if err != nil || !token.Valid {
		return utils.RespondError(c, "can not parse token")
	}
	claims, ok := token.Claims.(*model.JwtUserClaims)
	if !ok {
		return utils.RespondError(c, "can not extract claims")
	}

	user, err := query.User.Where(query.User.Username.Eq(claims.Username)).First()
	if err != nil {
		return utils.RespondError(c, "user not found")
	}
	return authOk(c, user)
}
