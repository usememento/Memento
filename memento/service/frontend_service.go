package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"github.com/gomarkdown/markdown"
	"github.com/gomarkdown/markdown/html"
	"github.com/gomarkdown/markdown/parser"
	"github.com/k3a/html2text"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
)

var domain = ""
var scheme = "https"

func getFileSystem(path string) http.FileSystem {
	return http.Dir(path)
}

// SEOFrontEndMiddleware is a middleware that serves the SPA frontend with SEO support.
func SEOFrontEndMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		domain = c.Request().Host
		scheme = c.Scheme()
		if strings.HasPrefix(c.Request().RequestURI, "/api") {
			return next(c)
		}
		if strings.HasPrefix(c.Request().RequestURI, "/public") {
			return next(c)
		}
		if strings.HasPrefix(c.Request().RequestURI, "/rss") {
			return next(c)
		}
		reqPath := c.Request().URL.Path
		if reqPath == "/robots.txt" {
			return handleRobotsTxt(c)
		} else if reqPath == "/sitemap.xml" {
			return handleSiteMap(c)
		} else if strings.HasPrefix(reqPath, "/icons/") || strings.HasPrefix(reqPath, "/favicon.png") {
			if memento.GetConfig().IconVersion > 0 {
				return handleIcon(c)
			}
		}
		fileSystem := getFileSystem("frontend/build/web")
		file, err := fileSystem.Open(reqPath)
		isHtml := reqPath == "/"
		if err != nil {
			if os.IsNotExist(err) {
				file, err = fileSystem.Open("index.html")
				isHtml = true
				if err != nil {
					return err
				}
			} else {
				return err
			}
		}
		defer func(file http.File) {
			err := file.Close()
			if err != nil {
				log.Errorf("Error closing file: %s\n", err.Error())
			}
		}(file)
		if fileInfo, _ := file.Stat(); fileInfo.IsDir() {
			file, err = fileSystem.Open("index.html")
			isHtml = true
			if err != nil {
				return err
			}
			defer func(file http.File) {
				err := file.Close()
				if err != nil {
					log.Errorf("Error closing file: %s\n", err.Error())
				}
			}(file)
		}
		if isHtml {
			bytes, err := io.ReadAll(file)
			if err != nil {
				return err
			}
			htmlRes := seoHtml(string(bytes), reqPath)
			return c.HTML(200, htmlRes)
		}
		bytes, err := io.ReadAll(file)
		if err != nil {
			return err
		}
		ext := filepath.Ext(reqPath)

		return c.Blob(200, getContentType(ext), bytes)
	}
}

func handleIcon(c echo.Context) error {
	path := c.Request().URL.Path
	iconPath := ""
	if path == "/favicon.png" {
		iconPath = filepath.Join(memento.GetBasePath(), "icons", "favicon.png")
	} else {
		path = strings.Replace(path, "/icons/", "", 1)
		iconPath = filepath.Join(memento.GetBasePath(), "icons", path)
	}
	return c.File(iconPath)
}

func getContentType(ext string) string {
	switch ext {
	case ".css":
		return "text/css"
	case ".js":
		return "application/javascript"
	case ".json":
		return "application/json"
	case ".png":
		return "image/png"
	case ".jpg":
		return "image/jpeg"
	case ".jpeg":
		return "image/jpeg"
	case ".gif":
		return "image/gif"
	case ".svg":
		return "image/svg+xml"
	case ".ico":
		return "image/x-icon"
	case ".webp":
		return "image/webp"
	case ".xml":
		return "application/xml"
	case ".pdf":
		return "application/pdf"
	default:
		return "text/plain"
	}
}

func seoHtml(html string, reqPath string) string {
	siteName := memento.GetConfig().SiteName
	description := memento.GetConfig().Description
	title := siteName
	url := scheme + "://" + domain + reqPath
	preview := "/icons/icon-192-maskable.png"
	seoArticle := ""
	icon := "/favicon.png"

	if memento.GetConfig().IconVersion > 0 {
		icon = icon + "?v=" + strconv.Itoa(int(memento.GetConfig().IconVersion))
	}

	func() {
		if strings.HasPrefix(reqPath, "/post/") {
			idStr := strings.TrimPrefix(reqPath, "/post/")
			id, err := strconv.Atoi(idStr)
			if err != nil {
				return
			}
			var post model.Post
			err = memento.Db().Model(&post).Where("id = ?", id).First(&post).Error
			if err != nil || post.IsPrivate {
				return
			}
			postView, err := utils.PostToView(&post, &model.UserViewModel{}, false)
			var author model.User
			err = memento.Db().Model(&author).Where("username = ?", post.Username).First(&author).Error
			if err != nil {
				return
			}
			authorView := utils.UserToView(&author, false)
			contentHtml := string(mdToHTML([]byte(postView.Content)))
			seoArticle = contentHtml
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
		} else if strings.HasPrefix(reqPath, "/user/") {
			username := strings.TrimPrefix(reqPath, "/user/")
			if strings.Contains(username, "/") {
				return
			}
			var user model.User
			err := memento.Db().Model(&user).Where("username = ?", username).First(&user).Error
			if err != nil {
				return
			}
			userView := utils.UserToView(&user, false)
			title = userView.Nickname
			description = userView.Bio
			preview = "/api/user/avatar/" + userView.Avatar
			seoArticle = userToSEOArticle(&user)
		}
	}()

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
	html = strings.Replace(html, "<!-- SEO article Body-->", seoArticle, 1)
	return html
}

func mdToHTML(md []byte) []byte {
	// create Markdown parser with extensions
	extensions := parser.CommonExtensions | parser.NoEmptyLineBeforeBlock | parser.MathJax
	p := parser.NewWithExtensions(extensions)
	doc := p.Parse(md)

	// create HTML renderer with extensions
	htmlFlags := html.CommonFlags | html.HrefTargetBlank
	opts := html.RendererOptions{Flags: htmlFlags}
	renderer := html.NewRenderer(opts)

	return markdown.Render(doc, renderer)
}

func findTitleInMd(md string) string {
	lines := strings.Split(md, "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "# ") {
			return strings.TrimPrefix(line, "# ")
		}
	}
	htmlContent := string(mdToHTML([]byte(md)))
	plain := html2text.HTML2Text(htmlContent)
	firstLine := strings.Split(plain, "\n")[0]
	if len([]rune(firstLine)) > 25 {
		firstLine = string([]rune(firstLine)[:25])
	}
	return firstLine
}

func userToSEOArticle(user *model.User) string {
	username := "<h1>" + user.Username + "</h1>"
	nickname := "<h2>" + user.Nickname + "</h2>"
	bio := "<p>" + user.Bio + "</p>"
	following := "<p>Following: " + strconv.Itoa(int(user.TotalFollows)) + "</p>"
	followers := "<p>Followers: " + strconv.Itoa(int(user.TotalFollower)) + "</p>"

	return username + nickname + bio + following + followers
}

func handleRobotsTxt(c echo.Context) error {
	return c.String(200, `User-agent: *
Disallow: /api/

Sitemap: https://`+domain+`/sitemap.xml
`)
}

func GenerateSiteMap() {
	var posts []model.Post
	err := memento.Db().Model(&posts).Where("is_private = ?", false).Find(&posts).Error
	if err != nil {
		return
	}
	sitemap := strings.Builder{}
	sitemap.WriteString(`<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">`)
	for _, post := range posts {
		sitemap.WriteString(`
<url>
	<loc>` + scheme + `://` + domain + `/public/article/` + strconv.Itoa(int(post.ID)) + `</loc>
	<lastmod>` + post.EditedAt.Format("2006-01-02") + `</lastmod>
</url>`)
	}
	sitemap.WriteString(`
</urlset>`)
	_ = os.WriteFile(filepath.Join(memento.GetBasePath(), "sitemap.xml"), []byte(sitemap.String()), 0644)
}

func handleSiteMap(c echo.Context) error {
	return c.File(filepath.Join(memento.GetBasePath(), "sitemap.xml"))
}
