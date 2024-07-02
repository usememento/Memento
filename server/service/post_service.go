package service

import (
	"Memento/server"
	"Memento/server/model"
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

func HandlePostCreate(c echo.Context) error {
	username := c.FormValue("username")
	var user model.User
	err := server.Memento.DbConn.First(&user, "username=?", username).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Username already exists
			return c.String(http.StatusBadRequest, fmt.Sprintf("username %s not exists", username))
		}
		return c.String(http.StatusBadRequest, "unknown query error")
	}
	post := model.Post{
		UserId:    int64(user.ID),
		Liked:     0,
		CreatedAt: time.Now(),
		EditedAt:  time.Now(),
	}
	err = server.Memento.DbConn.Create(&post).Error
	if err != nil {
		return c.String(http.StatusBadRequest, "unknown insertion error")
	}
	contentFile, err := c.FormFile("content")
	if err != nil {
		return c.String(http.StatusBadRequest, "post content not uploaded")
	}
	contentFilename := strconv.Itoa(int(post.ID)) + ".md"
	contentFilepath := path.Join(server.Memento.Config.FilePath, "files", contentFilename)

	contentBody, err := contentFile.Open()
	if err != nil {
		return c.String(http.StatusBadRequest, "can not open content file")
	}
	content, err := os.Create(contentFilepath)
	if err != nil {
		return c.String(http.StatusBadRequest, "os file open error")
	}
	defer content.Close()

	if _, err = io.Copy(content, contentBody); err != nil {
		return c.String(http.StatusBadRequest, "data copy error")
	}
	post.ContentUrl = contentFilename

	//------------
	// Read files
	//------------
	// Multipart form
	form, err := c.MultipartForm()
	if err != nil {
		return c.String(http.StatusBadRequest, "can not read multipart form")
	}
	files := form.File["files"]
	for _, file := range files {
		// Source
		src, err := file.Open()
		if err != nil {
			return c.String(http.StatusBadRequest, "form file open error")
		}
		defer src.Close()
		//ext := path.Ext(file.Filename)
		filename := fmt.Sprintf("%d-%s", post.ID, file.Filename)
		filepath := path.Join(server.Memento.Config.ServerConfig.FilePath, "files", filename)
		// Destination
		dst, err := os.Create(filepath)
		if err != nil {
			return c.String(http.StatusBadRequest, "os file open error")
		}
		defer dst.Close()
		// Copy
		if _, err = io.Copy(dst, src); err != nil {
			return c.String(http.StatusBadRequest, "data copy error")
		}
	}
	return c.String(http.StatusOK, "post created")
}
func HandlePostDelete(c echo.Context) error {
	return nil
}
func HandlePostEdit(c echo.Context) error {
	return nil
}
func HandlePostGet(c echo.Context) error {
	return nil
}
