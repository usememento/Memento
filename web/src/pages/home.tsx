import {useCallback, useEffect, useRef, useState} from "react";
import {IconButton, TapRegion} from "../components/button.tsx";
import {MdLock, MdOutlineFullscreen, MdOutlineImage, MdOutlineInfo, MdPublic} from "react-icons/md";
import {Tr, translate} from "../components/translate.tsx";
import {Button} from "@nextui-org/react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import app from "../app.ts";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";

export default function HomePage() {
    return <div>
        <Editor></Editor>
        <UserPosts></UserPosts>
    </div>
}

interface EditorData {
    text: string;
    isPublic: boolean;
}

function Editor({fullHeight}: { fullHeight?: boolean }) {
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

    return <div className={`w-full ${fullHeight ? "h-full" : ""} border-b px-4 pt-4 pb-2`}>
        <textarea placeholder={translate("Write down your thoughts")} className={"w-full focus:outline-none min-h-6 max-h-screen resize-none"} id={"editor"}
                  value={data.text} onChange={(v) => {
            setData({...data, text: v.target.value});
        }}></textarea>
        <div className={"h-8 w-full flex flex-row"}>
            <TapRegion onPress={() => {
                setData({...data, isPublic: !data.isPublic});
            }} borderRadius={12}>
                <div className={"w-20 h-8 flex flex-row items-center justify-center text-primary"}>
                    {data.isPublic ? <MdPublic size={20}/> : <MdLock size={20}/>}
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
            <Button className={"h-8 rounded-2xl"} color={"primary"}><Tr>Post</Tr></Button>
        </div>
    </div>
}

function UserPosts() {
    const [state, setState] = useState({
        posts: [] as Post[],
    });

    const isLoading = useRef(false);
    const pageRef = useRef(0);
    const maxPageRef = useRef(0);

    const loadPosts = useCallback(async () => {
        try {
            if (isLoading.current) return;
            isLoading.current = true;

            const [posts, maxPage] = await network.getPosts(app.user!.username, pageRef.current);

            maxPageRef.current = maxPage as number;

            setState(prevState => ({
                posts: [...prevState.posts, ...(posts as Post[])],
            }));

            pageRef.current += 1;
        }
        catch (e: any) {
            showMessage(e.toString());
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
    </div>
}