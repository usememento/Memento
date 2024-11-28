import {useSearchParams} from "react-router";
import {useCallback, useEffect, useRef, useState} from "react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import {Spinner} from "@nextui-org/react";
import {MdSearch} from "react-icons/md";
export default function SearchPage() {
    const [searchParams] = useSearchParams();

    const [text, setText] = useState(searchParams.get("keyword") || "");

    return <div className={"h-full w-full"}>
        <div className={"h-12 w-full border-b px-4 flex items-center"}>
            <MdSearch className={"text-2xl text-primary"}/>
            <div className={"flex-grow pl-2"}>
                <form onSubmit={(event) => {
                    event.preventDefault();
                    const value = (event.target as any).elements[0].value;
                    if (value && text !== value) {
                        setText(value);
                        window.history.pushState({}, "", `/search?keyword=${value}`);
                    }
                }}>
                    <input defaultValue={text} className={"w-full h-10 focus:outline-none text-lg"}/>
                </form>
            </div>
        </div>
        {text && <SearchResult text={text} key={text}></SearchResult>}
    </div>
}

function SearchResult({text}: { text: string }) {
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

            const [posts, maxPage] = await network.searchPosts(text, pageRef.current);

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
    }, [text]);

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