import app from "../app.ts";
import axios from 'axios';
import {Post} from "./model.ts";

export const network = {
    isRefreshing: false,
    init: () => {
        axios.interceptors.request.use((config) => {
            if(app.token)
                config.headers.Authorization = app.token;
            config.validateStatus = () => true;
            return config;
        });
        axios.interceptors.response.use(async (res) => {
            if(res.status === 401 && !network.isRefreshing) {
                try {
                    network.isRefreshing = true;
                    await network.refreshToken();
                    res = await axios.request(res.config);
                    return res;
                }
                catch (e) {
                    console.error("Failed to refresh token: ", e);
                    return res;
                }
                finally {
                    network.isRefreshing = false;
                }
            }
            if(res.status === 400) {
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
        const res = await axios.postForm(`${app.server}/api/auth/refresh`, {
            refreshToken: app.refreshToken,
        });
        app.token = res.data.token;
    },
    getPosts: async (username: string, page: number) => {
        const res = await axios.get(`${app.server}/api/post/userPosts?username=${username}&page=${page}`);
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
}

network.init();