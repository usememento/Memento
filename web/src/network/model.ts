/**
 * type UserViewModel struct {
 *    Username      string
 *    Nickname      string
 *    Bio           string
 *    TotalLiked    int64
 *    TotalComment  int64
 *    TotalPosts    int64
 *    TotalFiles    int64
 *    TotalFollower int64
 *    TotalFollows  int64
 *    RegisteredAt  time.Time
 *    Avatar        string
 *    IsFollowed    bool
 *    IsAdmin       bool
 * }
 */
export class User {
    username: string;
    nickname: string;
    bio: string;
    totalLikes: number;
    totalComments: number;
    totalPosts: number;
    totalFiles: number;
    totalFollowers: number;
    totalFollows: number;
    registeredAt: Date;
    avatar: string;
    isFollowed: boolean;
    isAdmin: boolean;

    constructor(json: any) {
        this.username = json.Username;
        this.nickname = json.Nickname;
        this.bio = json.Bio;
        this.totalLikes = json.TotalLiked;
        this.totalComments = json.TotalComment;
        this.totalPosts = json.TotalPosts;
        this.totalFiles = json.TotalFiles;
        this.totalFollowers = json.TotalFollower;
        this.totalFollows = json.TotalFollows;
        this.registeredAt = new Date(json.RegisteredAt);
        this.avatar = json.Avatar;
        this.isFollowed = json.IsFollowed;
        this.isAdmin = json.IsAdmin;
    }

    toJson() {
        return {
            Username: this.username,
            Nickname: this.nickname,
            Bio: this.bio,
            TotalLiked: this.totalLikes,
            TotalComment: this.totalComments,
            TotalPosts: this.totalPosts,
            TotalFiles: this.totalFiles,
            TotalFollower: this.totalFollowers,
            TotalFollows: this.totalFollows,
            RegisteredAt: this.registeredAt,
            Avatar: this.avatar,
            IsFollowed: this.isFollowed,
            IsAdmin: this.isAdmin,
        }
    }
}
