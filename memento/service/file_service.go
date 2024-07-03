package service

import (
	"Memento/memento"
	"Memento/memento/utils"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"io"
	"os"
	"path"
	"time"
)

func HandleFileUpload(c echo.Context) error {
	now := time.Now()
	//------------
	// Read files
	//------------
	// Multipart form
	file, err := c.FormFile("file")
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "can not read form file")
	}

	// Source
	src, err := file.Open()
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "form file open error")
	}
	defer src.Close()
	ext := path.Ext(file.Filename)
	filename := utils.Md5string(fmt.Sprintf("%d%s", now.UnixMilli(), file.Filename)) + ext
	filepath := path.Join(memento.GetFilePath(), filename)
	// Destination
	dst, err := os.Create(filepath)
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "os file open error")
	}
	defer dst.Close()
	// Copy
	if _, err = io.Copy(dst, src); err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "data copy error")
	}

	return utils.RespondOk(c, filepath)
}

func HandleFileDownload(c echo.Context) error {
	url := c.FormValue("url")
	return c.File(url)
}
