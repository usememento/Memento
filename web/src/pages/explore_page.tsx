import {useCallback, useEffect, useRef, useState} from "react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import {Spinner} from "@nextui-org/react";
import SearchBar from "../components/search.tsx";
import {TapRegion} from "../components/button.tsx";
import {router} from "../components/router.tsx";
import {Tr} from "../components/translate.tsx";

export default function ExplorePage() {
    const [showSidebar, setShowSidebar] = useState(window.innerWidth > 768);

    useEffect(() => {
        window.addEventListener("resize", () => {
            setShowSidebar(window.innerWidth > 768);
        });
        return () => window.removeEventListener("resize", () => {
            setShowSidebar(window.innerWidth > 768);
        });
    }, []);

    return <div className={"flex flex-row w-full h-full"}>
        <div className={"overflow-y-scroll h-full flex-grow"}>
            <UserPosts></UserPosts>
        </div>
        {showSidebar && <div className={"w-64 h-full border-l"}>
            <SearchBar />
            <div className={"h-4"}></div>
            <TagList/>
        </div>}
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

            const [posts, maxPage] = await network.getAllPosts(pageRef.current);

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

function TagList() {
    const [tags, setTags] = useState<string[] | null>(null);

    useEffect(() => {
        network.getTags(true).then(setTags);
    }, []);

    return <div className={"w-full"}>
        <div className={"h-8 flex flex-row items-center  font-bold ml-2  text-lg px-2 "}>
            <Tr>Tags</Tr>
        </div>
        {tags === null ? <Spinner/> : tags.map((tag, index) => {
            return <TapRegion onPress={() => {
                router.navigate(`/tag/${tag}`);
            }} key={index}>
                <div className={"h-10 w-full px-4 flex items-center text-primary"}>{tag}</div>
            </TapRegion>
        })} </div>
}