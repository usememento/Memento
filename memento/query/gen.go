// Code generated by gorm.io/gen. DO NOT EDIT.
// Code generated by gorm.io/gen. DO NOT EDIT.
// Code generated by gorm.io/gen. DO NOT EDIT.

package query

import (
	"context"
	"database/sql"

	"gorm.io/gorm"

	"gorm.io/gen"

	"gorm.io/plugin/dbresolver"
)

var (
	Q       = new(Query)
	Comment *comment
	File    *file
	Post    *post
	Tag     *tag
	User    *user
)

func SetDefault(db *gorm.DB, opts ...gen.DOOption) {
	*Q = *Use(db, opts...)
	Comment = &Q.Comment
	File = &Q.File
	Post = &Q.Post
	Tag = &Q.Tag
	User = &Q.User
}

func Use(db *gorm.DB, opts ...gen.DOOption) *Query {
	return &Query{
		db:      db,
		Comment: newComment(db, opts...),
		File:    newFile(db, opts...),
		Post:    newPost(db, opts...),
		Tag:     newTag(db, opts...),
		User:    newUser(db, opts...),
	}
}

type Query struct {
	db *gorm.DB

	Comment comment
	File    file
	Post    post
	Tag     tag
	User    user
}

func (q *Query) Available() bool { return q.db != nil }

func (q *Query) clone(db *gorm.DB) *Query {
	return &Query{
		db:      db,
		Comment: q.Comment.clone(db),
		File:    q.File.clone(db),
		Post:    q.Post.clone(db),
		Tag:     q.Tag.clone(db),
		User:    q.User.clone(db),
	}
}

func (q *Query) ReadDB() *Query {
	return q.ReplaceDB(q.db.Clauses(dbresolver.Read))
}

func (q *Query) WriteDB() *Query {
	return q.ReplaceDB(q.db.Clauses(dbresolver.Write))
}

func (q *Query) ReplaceDB(db *gorm.DB) *Query {
	return &Query{
		db:      db,
		Comment: q.Comment.replaceDB(db),
		File:    q.File.replaceDB(db),
		Post:    q.Post.replaceDB(db),
		Tag:     q.Tag.replaceDB(db),
		User:    q.User.replaceDB(db),
	}
}

type queryCtx struct {
	Comment ICommentDo
	File    IFileDo
	Post    IPostDo
	Tag     ITagDo
	User    IUserDo
}

func (q *Query) WithContext(ctx context.Context) *queryCtx {
	return &queryCtx{
		Comment: q.Comment.WithContext(ctx),
		File:    q.File.WithContext(ctx),
		Post:    q.Post.WithContext(ctx),
		Tag:     q.Tag.WithContext(ctx),
		User:    q.User.WithContext(ctx),
	}
}

func (q *Query) Transaction(fc func(tx *Query) error, opts ...*sql.TxOptions) error {
	return q.db.Transaction(func(tx *gorm.DB) error { return fc(q.clone(tx)) }, opts...)
}

func (q *Query) Begin(opts ...*sql.TxOptions) *QueryTx {
	tx := q.db.Begin(opts...)
	return &QueryTx{Query: q.clone(tx), Error: tx.Error}
}

type QueryTx struct {
	*Query
	Error error
}

func (q *QueryTx) Commit() error {
	return q.db.Commit().Error
}

func (q *QueryTx) Rollback() error {
	return q.db.Rollback().Error
}

func (q *QueryTx) SavePoint(name string) error {
	return q.db.SavePoint(name).Error
}

func (q *QueryTx) RollbackTo(name string) error {
	return q.db.RollbackTo(name).Error
}