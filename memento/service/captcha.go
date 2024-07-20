package service

import (
	"Memento/memento/utils"
	"bytes"
	"encoding/base64"
	"github.com/golang-jwt/jwt"
	"github.com/labstack/echo/v4"
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"math/rand"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

var secret = ""

const (
	squareSize  = 36
	imageWidth  = 256
	imageHeight = 160
)

func HandleGetCaptcha(c echo.Context) error {
	if secret == "" {
		for i := 0; i < 20; i++ {
			secret += string(rune(65 + rand.Intn(25)))
		}
	}
	dir, err := os.Open("./assets/captcha")
	if err != nil {
		return c.JSON(500, err.Error())
	}
	defer dir.Close()
	files, err := dir.Readdir(0)
	if err != nil {
		return c.JSON(500, err.Error())
	}
	imageFile := files[rand.Intn(len(files))]
	data, err := os.ReadFile(filepath.Join(dir.Name(), imageFile.Name()))
	if err != nil {
		return c.JSON(500, err.Error())
	}
	captchaAnswer := rand.Intn(80) + 20
	centerX := captchaAnswer*(imageWidth-squareSize)/100 + squareSize/2
	centerY := imageHeight / 2
	rect := image.Rect(centerX-squareSize/2, centerY-squareSize/2, centerX+squareSize/2, centerY+squareSize/2)
	slider, err := cropImage(data, rect.Min.X, rect.Min.Y, squareSize, squareSize)
	if err != nil {
		return c.JSON(500, err.Error())
	}
	bg, err := replaceRectangleWithColor(data, rect, image.NewUniform(color.RGBA{R: 211, G: 211, B: 211, A: 255}))
	if err != nil {
		return c.JSON(500, err.Error())
	}
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"answer":     captchaAnswer,
		"created_at": time.Now().Unix(),
	})
	identifier, err := t.SignedString([]byte(secret))
	if err != nil {
		return c.JSON(500, err.Error())
	}
	return c.JSON(200, echo.Map{
		"identifier": identifier,
		"slider":     base64.StdEncoding.EncodeToString(slider),
		"bg":         base64.StdEncoding.EncodeToString(bg),
	})
}

func HandleVerifyCaptcha(c echo.Context) error {
	identifier := c.FormValue("identifier")
	answerStr := c.FormValue("answer")
	if identifier == "" || answerStr == "" {
		return c.JSON(400, "Missing identifier or captcha")
	}
	answer, err := strconv.Atoi(answerStr)
	if err != nil {
		return c.JSON(400, "Invalid captcha")
	}
	t, err := jwt.Parse(identifier, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return c.JSON(400, "Invalid identifier")
	}
	claims, ok := t.Claims.(jwt.MapClaims)
	if !ok {
		return c.JSON(400, "Invalid identifier")
	}
	createTime := claims["created_at"].(float64)
	if createTime < float64(time.Now().Unix()-60) {
		return utils.RespondError(c, "Captcha expired")
	}
	trueAnswer := int(claims["answer"].(float64))
	if answer < trueAnswer-5 || answer > trueAnswer+5 {
		return utils.RespondError(c, "Invalid captcha")
	}
	t = jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"created at": time.Now().Unix(),
		"sub":        "captcha",
	})
	tokenString, err := t.SignedString([]byte(secret))
	if err != nil {
		return c.JSON(500, err.Error())
	}
	return c.JSON(200, echo.Map{
		"captcha_token": tokenString,
	})
}

func VerifyCaptchaToken(tokenString string) bool {
	t, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return []byte(secret), nil
	})
	if err != nil {
		return false
	}
	claims, ok := t.Claims.(jwt.MapClaims)
	if !ok {
		return false
	}
	if claims["sub"] != "captcha" {
		return false
	}
	createTime := int64(claims["created at"].(float64))
	if createTime < time.Now().Unix()-60*3 {
		return false
	}
	return true
}

func replaceRectangleWithColor(imageData []byte, rect image.Rectangle, c color.Color) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imageData))
	if err != nil {
		return nil, err
	}

	newImg := image.NewRGBA(img.Bounds())

	for x := 0; x < newImg.Bounds().Max.X; x++ {
		for y := 0; y < newImg.Bounds().Max.Y; y++ {
			if rect.Min.X <= x && x < rect.Max.X && rect.Min.Y <= y && y < rect.Max.Y {
				newImg.Set(x, y, c)
			} else {
				newImg.Set(x, y, img.At(x, y))
			}
		}
	}

	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, newImg, nil); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func cropImage(imgData []byte, x, y, width, height int) ([]byte, error) {
	img, _, err := image.Decode(bytes.NewReader(imgData))
	if err != nil {
		return nil, err
	}

	rect := image.Rect(x, y, x+width, y+height)
	croppedImg := image.NewRGBA(rect)

	draw.Draw(croppedImg, croppedImg.Bounds(), img, image.Point{x, y}, draw.Src)

	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, croppedImg, nil); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}
