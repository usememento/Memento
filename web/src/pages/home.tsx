import {useCallback, useEffect, useState} from "react";
import {IconButton, TapRegion} from "../components/button.tsx";
import {
    MdLock,
    MdOutlineImage,
    MdOutlineInfo,
    MdPublic
} from "react-icons/md";
import {Tr, translate} from "../components/translate.tsx";
import {Button, Spinner} from "@nextui-org/react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import app from "../app.ts";
import showMessage, {Loading} from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import HeatMapWidget from "../components/heat_map.tsx";
import SearchBar from "../components/search.tsx";
import {useNavigate} from "react-router";
import MultiPageList from "../components/multi_page_list.tsx";

export default function HomePage() {
    const [postsKey, setPostsKey] = useState(0);

    const [showSidebar, setShowSidebar] = useState(window.innerWidth > 768);

    const updatePosts = useCallback(() => {
        console.log("updatePosts");
        setPostsKey(prev => prev + 1);
    }, []);

    useEffect(() => {
        const listener = () => {
            setShowSidebar(window.innerWidth > 768);
        };
        window.addEventListener("resize", listener);
        return () => window.removeEventListener("resize", listener);
    }, []);

    const navigate = useNavigate();

    if(!app.user) {
        return <div className={"h-full w-full flex flex-col items-center justify-center"}>
            <Tr>Login required</Tr>
            <Button color={"primary"} className={"mt-2 h-8"} onClick={() => {
                navigate("/login");
            }}>Login</Button>
        </div>
    }

    return <div className={"flex flex-row w-full h-full"}>
        <div className={"h-full overflow-y-scroll flex-grow"}>
            <Editor updatePosts={updatePosts}></Editor>
            <UserPosts key={postsKey}></UserPosts>
        </div>
        {showSidebar&&app.user && <div className={"w-64 h-full border-l flex-shrink-0"} key={postsKey}>
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

    const [data, setData] = useState<EditorData>({text: "", isPublic: app.defaultPostVisibility === "public"});
    const [isUploading, setIsUploading] = useState(false);
    const [isUploadingImage, setIsUploadingImage] = useState(false);

    const uploadImage = useCallback(async () => {
        setIsUploadingImage(true);
        const input = document.createElement("input");
        input.type = "file";
        input.accept = "image/*";
        let isClicked = false;
        input.onchange = async () => {
            if(isClicked) return;
            isClicked = true;
            try {
                const file = input.files?.item(0);
                const id = await network.uploadFile(file!);
                setData(prev => ({
                    ...prev,
                    text: prev.text + `![image](${app.server}/api/file/download/${id})`
                }))
            }
            catch (e: any) {
                showMessage({text: e.toString()});
            }
            finally {
                setIsUploadingImage(false);
            }
        }
        input.click();
        input.oncancel = () => setIsUploadingImage(false);
    }, []);

    return <div className={`w-full ${fullHeight ? "h-full" : ""} border-b px-4 pt-4 pb-2`}>
        <textarea placeholder={translate("Write down your thoughts")} className={"w-full focus:outline-none min-h-6 resize-none px-2"} id={"editor"}
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
            <IconButton onPress={uploadImage} isLoading={isUploadingImage}>
                <MdOutlineImage/>
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
                    const editor = document.getElementById("editor")!;
                    editor.style.height = "auto";
                    editor.style.height = "48px";
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
    return <MultiPageList itemBuilder={(i) => <PostWidget post={i as Post}/>} loader={(page) => network.getPosts(app.user!.username!, page)}></MultiPageList>
}

function TagList() {
    const [tags, setTags] = useState<string[] | null>(null);

    const navigate = useNavigate();

    useEffect(() => {
        network.getTags(false).then(setTags);
    }, []);

    return <div className={"w-full"}>
        <div className={"h-8 flex flex-row items-center  font-bold ml-2  text-lg px-2 "}>
            <Tr>Tags</Tr>
        </div>
        {tags === null ? <div className={"w-full h-20 flex items-center justify-center"}>
            <Loading/>
        </div> : tags.map((tag, index) => {
            return <TapRegion onPress={() => {
                navigate(`/tag/${tag.replace('#', '')}`);
            }} key={index}>
                <div className={"h-10 w-full px-4 flex items-center text-primary"}>{tag}</div>
            </TapRegion>
        })} </div>
}