package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"fmt"
	"github.com/k3a/html2text"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"io"
	"os"
	"regexp"
	"strconv"
	"strings"
)

var (
	htmlTemplate = ""
)

func HandlePublicArticle(c echo.Context) error {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.JSON(400, "Invalid id")
	}
	if htmlTemplate == "" {
		file, err := os.Open("assets/public_article.html")
		if err != nil {
			return c.JSON(500, "Error reading template")
		}
		defer func(file *os.File) {
			err := file.Close()
			if err != nil {
				log.Errorf("Error closing file: %s\n", err.Error())
			}
		}(file)
		data, err := io.ReadAll(file)
		if err != nil {
			return c.JSON(500, "Error reading template")
		}
		htmlTemplate = string(data)
	}
	html, err := renderArticle(id)
	if err != nil {
		return c.JSON(404, "Article not found")
	}
	return c.HTMLBlob(200, []byte(html))
}

func renderArticle(id int) (string, error) {
	siteName := memento.GetConfig().SiteName
	description := memento.GetConfig().Description
	title := siteName
	url := scheme + "://" + domain + "/public/article/" + strconv.Itoa(id)
	preview := "/icons/icon-192-maskable.png"
	article := ""
	scripts := ""
	icon := "/favicon.png"

	html := htmlTemplate

	if memento.GetConfig().IconVersion > 0 {
		icon = icon + "?v=" + strconv.Itoa(int(memento.GetConfig().IconVersion))
	}
	var post model.Post
	err := memento.Db().Model(&post).Where("id = ?", id).First(&post).Error
	if err != nil || post.IsPrivate {
		return "", err
	}
	if post.IsPrivate {
		return "", fmt.Errorf("post is private")
	}
	postView, err := utils.PostToView(&post, &model.UserViewModel{}, false)
	var author model.User
	err = memento.Db().Model(&author).Where("username = ?", post.Username).First(&author).Error
	if err != nil {
		return "", err
	}
	authorView := utils.UserToView(&author, false)
	contentHtml := string(mdToHTML([]byte(renderTags(postView.Content))))
	article = contentHtml
	plain := html2text.HTML2Text(contentHtml)
	if len([]rune(plain)) > 100 {
		plain = string([]rune(plain)[:100])
	}
	description = plain
	title = findTitleInMd(postView.Content)
	preview = "/api/user/avatar/" + authorView.Avatar
	if title == "" {
		title = siteName
	}
	if strings.Contains(article, "<span class=\"math inline\">") {
		scripts += "<script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\"></script>\n"
	}

	description = strings.ReplaceAll(description, "\n", " ")
	description = strings.ReplaceAll(description, "\r", " ")
	regex := regexp.MustCompile(`\s+`)
	description = regex.ReplaceAllString(description, " ")
	preview = scheme + "://" + domain + preview

	html = strings.ReplaceAll(html, "{{Title}}", title)
	html = strings.ReplaceAll(html, "{{Description}}", description)
	html = strings.ReplaceAll(html, "{{SiteName}}", siteName)
	html = strings.ReplaceAll(html, "{{Url}}", url)
	html = strings.ReplaceAll(html, "{{Preview}}", preview)
	html = strings.ReplaceAll(html, "{{Icon}}", icon)
	html = strings.Replace(html, "{{Content}}", article, 1)
	html = strings.Replace(html, "{{Avatar}}", preview, 1)
	html = strings.Replace(html, "{{Nickname}}", authorView.Nickname, 1)
	html = strings.Replace(html, "{{Username}}", authorView.Username, 1)
	html = strings.Replace(html, "<!-- Scripts -->", scripts, 1)
	return html, nil
}

func renderTags(md string) string {
	md = strings.ReplaceAll(md, "\r\n", "\n")
	lines := strings.Split(md, "\n")
	for i, line := range lines {
		words := strings.Split(line, " ")
		for j, word := range words {
			if strings.HasPrefix(word, "#") {
				if strings.ReplaceAll(word, "#", "") == "" {
					continue
				}
				words[j] = "<a href=\"/tag/" + word[1:] + "\" class=\"tag\" target=\"_blank\">" + word + "</a>"
			}
		}
		lines[i] = strings.Join(words, " ")
	}
	return strings.Join(lines, "\n")
}
