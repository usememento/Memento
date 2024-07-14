package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
)

func AdminCheck(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		username := c.Get("username").(string)
		if username == "" {
			return c.JSON(401, echo.Map{
				"error": "unauthorized",
			})
		}
		user := model.User{
			Username: username,
		}
		err := memento.GetDbConnection().First(&user).Error
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

func HandleSetConfig(c echo.Context) error {
	enable := c.FormValue("enable_register") == "true"
	error := memento.SetIsEnableRegister(enable)
	if error != nil {
		log.Errorf(error.Error())
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
		"users": result,
		"maxPage": total / memento.PageSize,
	})
}

func HandleAdminDeleteUser(c echo.Context) error {
	username := c.Param("username")
	user := model.User {
		Username: username,
	}
	err := memento.GetDbConnection().First(&user).Error
	if err != nil {
		return utils.RespondError(c, "User not found")
	}
	return c.NoContent(200)
}

func HandleSetUserPermission(c echo.Context) error {
	isAdmin := c.FormValue("is_admin") == "true"
	username := c.FormValue("username")
	user := model.User {
		Username: username,
	}
	err := memento.GetDbConnection().First(&user).Error
	if err != nil {
		return utils.RespondError(c, "User not found")
	}
	user.IsAdmin = isAdmin
	err = memento.GetDbConnection().Update(&user).Error
	if err != nil {
		log.Errorf(err.Error())
		return utils.RespondError(c, "Failed")
	}
	return c.NoContent(200)
}