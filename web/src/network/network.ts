import app from "../app.ts";
import axios from 'axios';
import {HeatMapData, Post, User} from "./model.ts";
import {router} from "../components/router.tsx";
import showMessage from "../components/message.tsx";
import {translate} from "../components/translate.tsx";

export const network = {
    isRefreshing: false,
    init: () => {
        axios.interceptors.request.use((config) => {
            if(app.token && !config.url!.includes("/refresh"))
                config.headers.Authorization = app.token;
            config.validateStatus = () => true;
            return config;
        });
        axios.interceptors.response.use(async (res) => {
            if(res.status === 401 && !network.isRefreshing && app.token) {
                try {
                    network.isRefreshing = true;
                    await network.refreshToken();
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
            if(res.status === 400) {
                if(res.config.url!.includes("/refresh")) {
                    setTimeout(() => {
                        app.clearData();
                        router.navigate("/login");
                        showMessage({text: translate("Session expired, please login again")});
                    }, 200);
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
        app.token = res.data.token;
    },
    getPosts: async (username: string, page: number) => {
        const res = await axios.get(`${app.server}/api/post/userPosts?username=${username}&page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
    },
    getAllPosts: async (page: number) => {
        const res = await axios.get(`${app.server}/api/post/all?page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
    },
    getFollowPosts: async (page: number) => {
        const res = await axios.get(`${app.server}/api/post/following?page=${page}`);
        const json = res.data;
        return [json.posts as Post[], json.maxPage as number];
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
    }
}

network.init();