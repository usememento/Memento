import app from "../app.ts";

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
    registeredAt: string;
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
    createdAt: string;
    editedAt: string;
    content: string;
}

export function getAvatar(user: User | null) {
    let avatar = user?.avatar
    if (avatar && avatar !== "user.png") {
        avatar = `${app.server}/api/user/avatar/${avatar}`
    } else {
        avatar = '/user.png'
    }
    return avatar
}

export interface HeatMapData {
    memos: number;
    likes: number;
    map: { [key: string]: number }
}