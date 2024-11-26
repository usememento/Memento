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