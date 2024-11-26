import app from "../app.ts";
import {Post} from "./model.ts";

export const network = {
    getPosts: async (username: string, page: number) => {
        const res = await fetch(`${app.server}/api/post/userPosts?username=${username}&page=${page}`, {
            headers: {
                "Authorization": app.token ?? ""
            }
        });
        if(res.ok) {
            const json = await res.json();
            return [json.posts as Post[], json.maxPage as number];
        } else {
            const json = await res.json();
            throw new Error(json.message);
        }
    },
    createPost: async (content: string, isPublic: boolean) => {
        const res = await fetch(`${app.server}/api/post/create`, {
            method: "POST",
            body: "content=" + encodeURIComponent(content) + "&permission=" + (isPublic ? "public" : "private"),
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": app.token ?? ""
            }
        });
        if(res.ok) {
            return;
        } else {
            const json = await res.json();
            throw new Error(json.message);
        }
    }
}