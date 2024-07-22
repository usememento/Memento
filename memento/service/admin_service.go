package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"os"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
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
		"enable_register": memento.IsEnableRegister(),
	})
}

func HandleSetConfig(c echo.Context) error {
	enable := c.FormValue("enable_register") == "true"
	err := memento.SetIsEnableRegister(enable)
	if err != nil {
		log.Errorf(err.Error())
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
	err := memento.GetDbConnection().Model(&model.User{}).Where("username = ?", username).Update("is_admin", isAdmin).Error
	if err != nil {
		return utils.RespondError(c, "Failed")
	}
	return c.NoContent(200)
}
