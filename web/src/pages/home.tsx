import {useCallback, useEffect, useRef, useState} from "react";
import {IconButton, TapRegion} from "../components/button.tsx";
import {
    MdLock,
    MdOutlineFullscreen,
    MdOutlineImage,
    MdOutlineInfo,
    MdPublic
} from "react-icons/md";
import {Tr, translate} from "../components/translate.tsx";
import {Button, Spinner} from "@nextui-org/react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import app from "../app.ts";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import HeatMapWidget from "../components/heat_map.tsx";
import {router} from "../components/router.tsx";
import SearchBar from "../components/search.tsx";

export default function HomePage() {
    const [postsKey, setPostsKey] = useState(0);

    const [showSidebar, setShowSidebar] = useState(window.innerWidth > 768);

    const updatePosts = useCallback(() => {
        console.log("updatePosts");
        setPostsKey(prev => prev + 1);
    }, []);

    useEffect(() => {
        window.addEventListener("resize", () => {
            setShowSidebar(window.innerWidth > 768);
        });
        return () => window.removeEventListener("resize", () => {
            setShowSidebar(window.innerWidth > 768);
        });
    }, []);

    if(!app.user) {
        return <div className={"h-full w-full flex flex-col items-center justify-center"}>
            <Tr>Login required</Tr>
            <Button color={"primary"} className={"mt-2 h-8"} onClick={() => {
                router.navigate("/login");
            }}>Login</Button>
        </div>
    }

    return <div className={"flex flex-row w-full h-full"}>
        <div className={"flex-grow h-full overflow-y-scroll"}>
            <Editor updatePosts={updatePosts}></Editor>
            <UserPosts key={postsKey}></UserPosts>
        </div>
        {showSidebar&&app.user && <div className={"w-64 h-full border-l"} key={postsKey}>
            <SearchBar />
            <div className={"h-2"}></div>
            <HeatMapWidget username={app.user!.username}></HeatMapWidget>
            <TagList/>
        </div>}
    </div>
}

interface EditorData {
    text: string;
    isPublic: boolean;
}

function Editor({fullHeight, updatePosts}: { fullHeight?: boolean, updatePosts: () => void }) {
    useEffect(() => {
        const editor = document.getElementById("editor")!;
        const listener = () => {
            editor.style.height = "auto";
            editor.style.height = editor.scrollHeight + "px";
        }
        editor.addEventListener("input", listener);
        return () => editor.removeEventListener("input", listener);
    }, []);

    const [data, setData] = useState<EditorData>({text: "", isPublic: true});
    const [isUploading, setIsUploading] = useState(false);

    return <div className={`w-full ${fullHeight ? "h-full" : ""} border-b px-4 pt-4 pb-2`}>
        <textarea placeholder={translate("Write down your thoughts")} className={"w-full focus:outline-none min-h-6 max-h-screen resize-none px-2"} id={"editor"}
                  value={data.text} onChange={(v) => {
            setData({...data, text: v.target.value});
        }}></textarea>
        <div className={"h-8 w-full flex flex-row"}>
            <TapRegion onPress={() => {
                setData({...data, isPublic: !data.isPublic});
            }} borderRadius={12}>
                <div className={"h-8 flex flex-row items-center justify-center text-primary text-sm px-2"}>
                    {data.isPublic ? <MdPublic size={18}/> : <MdLock size={18}/>}
                    <span className={"w-2"}></span>
                    <Tr>{data.isPublic ? "Public" : "Private"}</Tr>
                </div>
            </TapRegion>
            <IconButton onPress={() => {
                // TODO: Upload image
            }}>
                <MdOutlineImage/>
            </IconButton>
            <IconButton onPress={() => {
                // TODO: Full screen
            }}>
                <MdOutlineFullscreen/>
            </IconButton>
            <IconButton onPress={() => {
                window.open("https://github.com/usememento/Memento/blob/master/doc/ContentSyntax.md")
            }}>
                <MdOutlineInfo/>
            </IconButton>
            <div className={"flex-grow"}></div>
            <Button className={"h-8 rounded-2xl"} color={"primary"} onClick={async () => {
                if(isUploading) return;
                setIsUploading(true);
                try {
                    await network.createPost(data.text, data.isPublic);
                    setData({text: "", isPublic: true});
                    showMessage({text: translate("Post created")});
                    updatePosts();
                } catch (e: any) {
                    showMessage({text: e.toString()});
                } finally {
                    setIsUploading(false);
                }
            }}>{isUploading ? <Spinner color={"default"} size={"sm"}></Spinner> : <Tr>Post</Tr>}</Button>
        </div>
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

            const [posts, maxPage] = await network.getPosts(app.user!.username, pageRef.current);

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
            return <PostWidget key={index} post={post}></PostWidget>
        })}
        {state.isLoading && <div className={"h-10 w-full flex flex-row items-center justify-center"}>
            <Spinner size={"md"}/>
        </div>}
    </div>
}

function TagList() {
    const [tags, setTags] = useState<string[] | null>(null);

    useEffect(() => {
        network.getTags(false).then(setTags);
    }, []);

    return <div className={"w-full"}>
        <div className={"h-8 flex flex-row items-center  font-bold ml-2  text-lg px-2 "}>
            <Tr>Tags</Tr>
        </div>
        {tags === null ? <Spinner /> : tags.map((tag, index) => {
            return <TapRegion onPress={() => {
                router.navigate(`/tag/${tag}`);
            }} key={index}>
                <div className={"h-10 w-full px-4 flex items-center text-primary"}>{tag}</div>
            </TapRegion>
        })} </div>
}