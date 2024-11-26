import app from "../app.ts";
import {Post} from "./model.ts";

export const network = {
    getPosts: async (username: string, page: number) => {
        const res = await fetch(`${app.server}/api/post/userPosts?username=${username}&page=${page}`);
        if(res.ok) {
            const json = await res.json();
            return [json.posts as Post[], json.maxPage as number];
        } else {
            const json = await res.json();
            throw new Error(json.message);
        }
    },
}