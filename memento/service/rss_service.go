package service

import (
	"Memento/memento"
	"Memento/memento/model"
	"Memento/memento/utils"
	"errors"
	"github.com/k3a/html2text"
	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

func HandleRss(c echo.Context) error {
	username := c.Param("username")
	if username == "" {
		return c.JSON(400, "username is required")
	}
	rss, err := getRss(username)
	if err != nil {
		return c.JSON(404, err.Error())
	}
	return c.XMLBlob(200, []byte(rss))
}

// / getRss load cached RSS feed for a user, or generate a new one if not cached
func getRss(username string) (string, error) {
	rssPath := filepath.Join(memento.GetBasePath(), "rss", username+".xml")
	file, err := os.Open(rssPath)
	if os.IsNotExist(err) {
		return cacheRss(username)
	}
	defer func(file *os.File) {
		err := file.Close()
		if err != nil {
			log.Errorf("Error closing file: %s\n", err.Error())
		}
	}(file)
	data, err := io.ReadAll(file)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// / cacheRss generates a new RSS feed for a user and saves it to a file
func cacheRss(username string) (string, error) {
	rss, err := buildRss(username)
	if err != nil {
		return "", err
	}
	rssPath := filepath.Join(memento.GetBasePath(), "rss", username+".xml")
	if _, err := os.Stat(filepath.Dir(rssPath)); os.IsNotExist(err) {
		if err := os.MkdirAll(filepath.Dir(rssPath), 0750); err != nil {
			log.Errorf("Error creating directory: %s\n", err.Error())
		}
	}
	err = os.WriteFile(rssPath, []byte(rss), 0644)
	if err != nil {
		log.Errorf("Error writing RSS file: %s\n", err.Error())
	}
	return rss, nil
}

// / buildRss generates an RSS feed for a user
func buildRss(username string) (string, error) {
	var user model.User
	if err := memento.GetDbConnection().Where("username = ?", username).First(&user).Error; err != nil {
		return "", errors.New("user not found")
	}
	var posts []model.Post
	if err := memento.GetDbConnection().Where(&model.Post{Username: username, IsPrivate: false}).Order("created_at desc").Limit(10).Find(&posts).Error; err != nil {
		return "", errors.New("error fetching posts")
	}
	rss := strings.Builder{}
	rss.WriteString("<rss version=\"2.0\">\n")
	rss.WriteString("<channel>\n")
	rss.WriteString("<title>" + user.Nickname + "</title>\n")
	rss.WriteString("<link>" + scheme + "://" + domain + "/user/" + user.Username + "</link>\n")
	rss.WriteString("<description>" + user.Bio + "</description>\n")
	for _, post := range posts {
		postView, err := utils.PostToView(&post, &model.UserViewModel{}, false)
		if err != nil {
			continue
		}
		contentHtml := string(mdToHTML([]byte(postView.Content)))
		plain := html2text.HTML2Text(contentHtml)
		if len([]rune(plain)) > 100 {
			plain = string([]rune(plain)[:100])
		}
		rss.WriteString("<item>\n")
		rss.WriteString("<title>" + validateString(findTitleInMd(postView.Content)) + "</title>\n")
		rss.WriteString("<link>" + scheme + "://" + domain + "/public/article/" + strconv.Itoa(int(post.ID)) + "</link>\n")
		rss.WriteString("<description>" + validateString(plain) + "</description>\n")
		rss.WriteString("<pubDate>" + post.CreatedAt.Format(time.RFC1123) + "</pubDate>\n")
		rss.WriteString("</item>\n")
	}
	rss.WriteString("</channel>\n")
	rss.WriteString("</rss>\n")
	return rss.String(), nil
}

// / validateString replaces special characters in a string with their HTML entities
func validateString(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	s = strings.ReplaceAll(s, "\"", "&quot;")
	s = strings.ReplaceAll(s, "'", "&apos;")
	s = strings.ReplaceAll(s, "\n", " ")
	s = strings.ReplaceAll(s, "\r", " ")
	s = strings.ReplaceAll(s, "\t", " ")
	regex := regexp.MustCompile(`\s+`)
	s = regex.ReplaceAllString(s, " ")
	return s
}
