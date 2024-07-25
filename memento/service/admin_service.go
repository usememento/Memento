package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"bytes"
	"errors"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"github.com/nfnt/resize"
	"image"
	"image/color"
	"image/draw"
	"image/png"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strconv"
)

func AdminCheck(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		username := c.Get("username").(string)
		if username == "" {
			return c.JSON(400, echo.Map{
				"error": "Admin permission required",
			})
		}
		var user model.User
		err := memento.GetDbConnection().First(&user, "username=?", username).Error
		if err != nil {
			return c.JSON(401, echo.Map{
				"error": "User not found",
			})
		}
		if !user.IsAdmin {
			return c.JSON(401, echo.Map{
				"error": "Admin required",
			})
		}
		return next(c)
	}
}

func HandleGetConfigs(c echo.Context) error {
	return c.JSON(200, echo.Map{
		"enable_register": memento.GetConfig().EnableRegister,
		"site_name":       memento.GetConfig().SiteName,
		"description":     memento.GetConfig().Description,
		"icon_version":    memento.GetConfig().IconVersion,
	})
}

func HandleSetConfig(c echo.Context) error {
	enable := c.FormValue("enable_register")
	siteName := c.FormValue("site_name")
	description := c.FormValue("description")
	if enable != "" {
		memento.GetConfig().EnableRegister = enable == "true"
	}
	if siteName != "" {
		memento.GetConfig().SiteName = siteName
	}
	if description != "" {
		memento.GetConfig().Description = description
	}
	err := memento.WriteConfig()
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	return c.NoContent(200)
}

func HandleListUsers(c echo.Context) error {
	pageStr := c.QueryParam("page")
	page, err := strconv.Atoi(pageStr)
	if err != nil {
		return utils.RespondError(c, "Invalid page")
	}
	users := make([]model.User, 0, memento.PageSize)
	err = memento.GetDbConnection().
		Offset(page * memento.PageSize).
		Limit(memento.PageSize).
		Find(&users).
		Error
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	var total int64
	err = memento.GetDbConnection().
		Model(&model.User{}).
		Count(&total).
		Error
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	result := make([]model.UserViewModel, 0, len(users))
	for _, user := range users {
		result = append(result, *utils.UserToView(&user, false))
	}
	return c.JSON(200, echo.Map{
		"users":      result,
		"maxPage":    utils.MaxPage(total),
		"totalUsers": total,
	})
}

func HandleAdminDeleteUser(c echo.Context) error {
	username := c.Param("username")
	var user model.User
	err := memento.GetDbConnection().First(&user, "username=?", username).Error
	if err != nil {
		return utils.RespondError(c, "User not found")
	}
	err = os.Remove(user.AvatarUrl)
	if err != nil {
		log.Errorf(err.Error())
	}
	err = memento.GetDbConnection().Delete(&user).Error
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	return c.NoContent(200)
}

func HandleSetUserPermission(c echo.Context) error {
	isAdmin := c.FormValue("is_admin") == "true"
	username := c.FormValue("username")
	err := memento.GetDbConnection().
		Model(&model.User{}).
		Where("username = ?", username).
		Update("is_admin", isAdmin).
		Error
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	return c.NoContent(200)
}

func HandleSetNewIcon(c echo.Context) error {
	file, err := c.FormFile("icon")
	if err != nil {
		return utils.RespondError(c, "Icon required")
	}
	src, err := file.Open()
	if err != nil {
		return utils.RespondError(c, "Failed to open file")
	}
	defer func(src multipart.File) {
		err := src.Close()
		if err != nil {
			log.Errorf(err.Error())
		}
	}(src)
	img, err := io.ReadAll(src)
	if err != nil {
		return utils.RespondError(c, "Failed to read file")
	}
	err = setIcon(img)
	if err != nil {
		return utils.RespondError(c, err.Error())
	}
	memento.GetConfig().IconVersion++
	_ = memento.WriteConfig()
	return c.NoContent(200)
}

func setIcon(data []byte) error {
	img, _, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return err
	}
	// 512x512 resolution required
	if img.Bounds().Dx() != 512 || img.Bounds().Dy() != 512 {
		return errors.New("invalid resolution: 512x512 required")
	}
	img512Mask := img
	img192Mask := resize.Resize(192, 192, img, resize.Lanczos3)
	img32 := resize.Resize(32, 32, img, resize.Lanczos3)
	img32 = circularCrop(img32)
	img192 := circularCrop(img192Mask)
	img512 := circularCrop(img512Mask)
	path := filepath.Join(memento.GetBasePath(), "icons")
	err = os.MkdirAll(path, 0777)
	if err != nil {
		return err
	}
	err = saveImage(img32, filepath.Join(path, "favicon.png"))
	if err != nil {
		return err
	}
	err = saveImage(img192, filepath.Join(path, "Icon-192.png"))
	if err != nil {
		return err
	}
	err = saveImage(img512, filepath.Join(path, "Icon-512.png"))
	if err != nil {
		return err
	}
	err = saveImage(img192Mask, filepath.Join(path, "icon-192-maskable.png"))
	if err != nil {
		return err
	}
	err = saveImage(img512Mask, filepath.Join(path, "icon-512-maskable.png"))
	if err != nil {
		return err
	}
	return nil
}

type circle struct {
	p image.Point
	r int
}

func (c *circle) ColorModel() color.Model {
	return color.AlphaModel
}

func (c *circle) Bounds() image.Rectangle {
	return image.Rect(c.p.X-c.r, c.p.Y-c.r, c.p.X+c.r, c.p.Y+c.r)
}

func (c *circle) At(x, y int) color.Color {
	xx, yy, rr := float64(x-c.p.X)+0.5, float64(y-c.p.Y)+0.5, float64(c.r)
	if xx*xx+yy*yy < rr*rr {
		return color.Alpha{A: 255}
	}
	return color.Alpha{}
}

func circularCrop(img image.Image) image.Image {
	// 放大图像以提高抗锯齿效果
	upscaleFactor := 2
	upscaleWidth := img.Bounds().Dx() * upscaleFactor
	upscaleHeight := img.Bounds().Dy() * upscaleFactor
	upscaledImg := resize.Resize(uint(upscaleWidth), uint(upscaleHeight), img, resize.Lanczos3)

	dst := image.NewRGBA(image.Rect(0, 0, upscaleWidth, upscaleHeight))
	c := circle{
		p: image.Point{X: upscaleWidth / 2, Y: upscaleHeight / 2},
		r: upscaleWidth / 2, // 保持圆形半径与放大后的图像尺寸一致
	}

	draw.DrawMask(dst, dst.Bounds(), upscaledImg, image.Point{}, &c, image.Point{}, draw.Over)

	resultImg := resize.Resize(uint(img.Bounds().Dx()), uint(img.Bounds().Dy()), dst, resize.Lanczos3)

	return resultImg
}

func saveImage(img image.Image, path string) error {
	f, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0666)
	if err != nil {
		return err
	}
	err = png.Encode(f, img)
	if err != nil {
		return err
	}
	err = f.Close()
	if err != nil {
		return err
	}
	return nil
}
