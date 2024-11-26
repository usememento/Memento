export interface User {
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
}

export interface Post {
    isLiked: boolean;
    isPrivate: boolean;
    postID: number;
    user: User;
    totalLiked: number;
    totalComment: number;
    createdAt: Date;
    editedAt: Date;
    content: string;
}