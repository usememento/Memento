import {useCallback, useEffect, useRef, useState} from "react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import {Button, Spinner} from "@nextui-org/react";
import app from "../app.ts";
import {Tr} from "../components/translate.tsx";
import {router} from "../components/router.tsx";

export default function FollowingPage() {
    if(!app.user) {
        return <div className={"h-full w-full flex flex-col items-center justify-center"}>
            <Tr>Login required</Tr>
            <Button color={"primary"} className={"mt-2 h-8"} onClick={() => {
                router.navigate("/login");
            }}>Login</Button>
        </div>
    }

    return <div className={"overflow-y-scroll"}>
        <UserPosts></UserPosts>
    </div>
}

function UserPosts() {
    const [state, setState] = useState({
        posts: [] as Post[],
        isLoading: false,
    });

    const isLoading = useRef(false);
    const pageRef = useRef(0);
    const maxPageRef = useRef(0);

    const loadPosts = useCallback(async () => {
        try {
            if (isLoading.current || pageRef.current > maxPageRef.current) return;
            isLoading.current = true;
            setState(prev => ({...prev, isLoading: true}));

            const [posts, maxPage] = await network.getFollowPosts(pageRef.current);

            maxPageRef.current = maxPage as number;

            setState(prevState => ({
                posts: [...prevState.posts, ...(posts as Post[])],
                isLoading: false,
            }));

            pageRef.current += 1;
        }
        catch (e: any) {
            showMessage({text: e.toString()});
        } finally {
            isLoading.current = false;
        }
    }, []);

    useEffect(() => {
        loadPosts();

        const listener = () => {
            if (
                window.innerHeight + window.scrollY >= document.body.offsetHeight &&
                pageRef.current < maxPageRef.current &&
                !isLoading.current
            ) {
                loadPosts();
            }
        }

        window.addEventListener("scroll", listener);
        return () => window.removeEventListener("scroll", listener);
    }, [loadPosts]);

    return <div>
        {state.posts.map((post, index) => {
            return <PostWidget key={index} post={post} showUser={true}></PostWidget>
        })}
        {state.isLoading && <div className={"h-10 w-full flex flex-row items-center justify-center"}>
            <Spinner size={"md"}/>
        </div>}
    </div>
}