package service

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"net/http"
	"strings"
)

func getFileSystem(path string) http.FileSystem {
	return http.Dir(path)
}

func ServeFrontend(e *echo.Echo) {
	// Use echo gzip middleware to compress the response.
	// Reference: https://echo.labstack.com/docs/middleware/gzip
	skipper := func(c echo.Context) bool {
		return strings.HasPrefix(c.Path(), "/api")
	}

	// Use echo static middleware to serve the built dist folder.
	// Reference: https://github.com/labstack/echo/blob/master/middleware/static.go
	e.Use(middleware.StaticWithConfig(middleware.StaticConfig{
		HTML5:      true,
		Filesystem: getFileSystem("frontend/build/web"),
		Skipper:    skipper,
	}))
}
