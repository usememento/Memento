import app from "../app.ts";
import axios from 'axios';
import { CommentWithPost, HeatMapData, Post, User, Comment, Resource, ServerConfig } from "./model.ts";

export const network = {
    isRefreshing: false,
    init: () => {
        axios.interceptors.request.use((config) => {
            if (app.token && !config.url!.includes("/refresh"))
                config.headers.Authorization = app.token;
            config.validateStatus = () => true;
            return config;
        });
        axios.interceptors.response.use(async (res) => {
            if (network.isRefreshing) {
                while (network.isRefreshing) {
                    await new Promise((resolve) => {
                        setTimeout(() => {
                            resolve(null);
                        }, 100);
                    })
                }
                let config = res.config;
                config.headers.Authorization = app.token;
                res = await axios.request(res.config);
                return res;
            }

            if (res.status === 401 && !network.isRefreshing && app.token) {
                try {
                    network.isRefreshing = true;
                    await network.refreshToken();
                    let config = res.config;
                    config.headers.Authorization = app.token;
                    res = await axios.request(res.config);
                    return res;
                }
                catch (e) {
                    console.error("Failed to refresh token: ", e);
                    throw new Error("Failed to refresh token");
                }
                finally {
                    network.isRefreshing = false;
                }
            }
            if (res.status === 400) {
                if (res.config.url!.includes("/refresh")) {
                    setTimeout(() => {
                        app.clearData();
                        window.location.reload();
                    }, 500);
                }
                throw new Error(res.data.message);
            }
            else if (res.status === 401) {
                throw new Error("Unauthorized");
            } else if (res.status >= 400) {
                throw new Error(`Invalid Status Code: ${res.status}`);
            }
            return res;
        });
    },
    refreshToken: async () => {
        const res = await axios.postForm(`${app.server}/api/user/refresh`, {
            refreshToken: app.refreshToken,
        });
        app.token = res.data.accessToken;
        app.refreshToken = res.data.refreshToken;
        app.writeData();
    },
    getPosts: async (username: string, page: number) => {
        const res = await axios.get(`${app.server}/api/post/userPosts?username=${username}&page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number] as [Post[], number];
    },
    getAllPosts: async (page: number) => {
        const res = await axios.get(`${app.server}/api/post/all?page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number] as [Post[], number];
    },
    getFollowPosts: async (page: number) => {
        const res = await axios.get(`${app.server}/api/post/following?page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number] as [Post[], number];
    },
    createPost: async (content: string, isPublic: boolean) => {
        await axios.postForm(`${app.server}/api/post/create`, {
            content: content,
            permission: isPublic ? "public" : "private",
        });
    },
    likePost: async (postId: number) => {
        await axios.postForm(`${app.server}/api/post/like`, {
            id: postId,
        });
    },
    unlikePost: async (postId: number) => {
        await axios.postForm(`${app.server}/api/post/unlike`, {
            id: postId,
        });
    },
    getHeatMap: async (username: string) => {
        const res = await axios.get(`${app.server}/api/user/heatmap?username=${username}`);
        return res.data as HeatMapData;
    },
    searchPosts: async (query: string, page: number) => {
        const res = await axios.get(`${app.server}/api/search/post?keyword=${query}&page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
    },
    getTags: async (all: boolean) => {
        const res = await axios.get(`${app.server}/api/post/tags?type=${all ? "all" : "user"}`);
        return res.data as string[];
    },
    getUser: async (username: string) => {
        const res = await axios.get(`${app.server}/api/user/get?username=${username}`);
        return res.data as User;
    },
    getUserLikes: async (username: string, page: number) => {
        const res = await axios.get(`${app.server}/api/post/likedPosts?username=${username}&page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
    },
    getTaggedPosts: async (tag: string, page: number) => {
        const res = await axios.get(`${app.server}/api/post/taggedPosts?tag=${tag}&page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
    },
    getComments: async (postId: number, page: number) => {
        const res = await axios.get(`${app.server}/api/comment/postComments?id=${postId}&page=${page}`);
        const json = res.data;
        return [json.comments as Comment[], json.maxPage as number];
    },
    getUserComments: async (username: string, page: number) => {
        const res = await axios.get(`${app.server}/api/comment/userComments?username=${username}&page=${page}`);
        const json = res.data;
        return [json.comments as CommentWithPost[], json.maxPage as number];
    },
    sendComment: async (postId: number, content: string) => {
        await axios.postForm(`${app.server}/api/comment/create`, {
            id: postId,
            content: content,
        });
    },
    likeComment: async (commentId: number) => {
        await axios.postForm(`${app.server}/api/comment/like`, {
            id: commentId,
        });
    },
    unlikeComment: async (commentId: number) => {
        await axios.postForm(`${app.server}/api/comment/unlike`, {
            id: commentId,
        });
    },
    deletePost: async (postId: number) => {
        await axios.delete(`${app.server}/api/post/delete/${postId}`);
    },
    editPost: async (postId: number, content: string, isPublic: boolean) => {
        await axios.postForm(`${app.server}/api/post/edit`, {
            id: postId,
            content: content,
            permission: isPublic ? "public" : "private",
        });
    },
    getPost: async (postId: string | number) => {
        const res = await axios.get(`${app.server}/api/post/get?id=${postId}`);
        return res.data as Post;
    },
    getResources: async (page: number) => {
        const res = await axios.get(`${app.server}/api/file/all?page=${page}`);
        const json = res.data;
        return [json.files as Resource[], json.maxPage as number] as [Resource[], number];
    },
    uploadFile: async (file: File, onUploadProgress?: (progress: number) => void) => {
        const formData = new FormData();
        formData.append("file", file);
        const res = await axios.post(`${app.server}/api/file/upload`, formData, {
            onUploadProgress: (e) => {
                if (onUploadProgress != null)
                    onUploadProgress(e.loaded / (e.total ?? file.size));
            }
        });
        return res.data.ID as string;
    },
    deleteFile: async (fileId: string) => {
        await axios.delete(`${app.server}/api/file/delete/${fileId}`);
    },
    editInfo: async (nickname: string | null, bio: string | null, avatar: File | null) => {
        const data = new FormData();
        if (nickname) data.append("nickname", nickname);
        if (bio) data.append("bio", bio);
        if (avatar) data.append("avatar", avatar);
        const user = await axios.post(`${app.server}/api/user/edit`, data);
        app.user = user.data as User;
        app.writeData();
    },
    changePassword: async (oldPassword: string, newPassword: string) => {
        await axios.postForm(`${app.server}/api/user/changePwd`, {
            oldPassword: oldPassword,
            newPassword: newPassword,
        });
    },
    getServerConfig: async () => {
        const res = await axios.get(`${app.server}/api/admin/config`);
        return res.data as ServerConfig;
    },
    setServerConfig: async (config: ServerConfig) => {
        await axios.postForm(`${app.server}/api/admin/config`, config);
    },
    setSiteIcon: async (icon: File) => {
        const formData = new FormData();
        formData.append("icon", icon);
        await axios.post(`${app.server}/api/admin/setIcon`, formData);
    },
    listUsers: async (page: number) => {
        const res = await axios.get(`${app.server}/api/admin/listUsers?page=${page}`);
        const json = res.data;
        return [json.users as User[], json.maxPage as number] as [User[], number];
    },
    deleteUser: async (username: string) => {
        await axios.delete(`${app.server}/api/admin/deleteUser/${username}`);
    },
    setPermission: async (username: string, is_admin: boolean) => {
        await axios.postForm(`${app.server}/api/admin/setPermission`, {
            username: username,
            is_admin: is_admin ? "true" : "false",
        });
    }
}

network.init();