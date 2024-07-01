package service

import "github.com/labstack/echo/v4"

func HandlePostCreate(c echo.Context) error {
	username := c.FormValue("username")
	password := c.FormValue("password")

	return nil
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
