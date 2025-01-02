import {useCallback, useEffect, useRef, useState} from "react";
import {TapRegion} from "../components/button.tsx";
import {Tr} from "../components/translate.tsx";
import {Button} from "@nextui-org/react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import app from "../app.ts";
import {Loading} from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import HeatMapWidget from "../components/heat_map.tsx";
import SearchBar from "../components/search.tsx";
import {useNavigate} from "react-router";
import MultiPageList from "../components/multi_page_list.tsx";
import Editor, {EditorData} from "../components/editor.tsx";

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
            <HomePageEditor updatePosts={updatePosts}></HomePageEditor>
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

function HomePageEditor({updatePosts}: { updatePosts: () => void }) {
    const value = useRef({
        text: "",
        isPublic: true,
    })
    
    const submit = useCallback(async () => {
        if(value.current.text.trim().length === 0) {
            throw "Post cannot be empty";
        }
        await network.createPost(value.current.text, value.current.isPublic);
        value.current = {
            text: "",
            isPublic: true,
        };
        updatePosts();
    }, [updatePosts]);

    const onChanged = useCallback((data: EditorData) => {
        value.current = {
            text: data.text,
            isPublic: data.isPublic,
        };
    }, []);

    return <Editor onChanged={onChanged} submit={submit} fullHeight={false}/>
}

function UserPosts() {
    const loader = useCallback((page: number) => network.getPosts(app.user!.username!, page), []);
    const deleteItemRef = useRef<((item: Post) => void) | null>(null);
    const builder = useCallback((i: Post) => <PostWidget post={i} onDelete={() => deleteItemRef.current!(i)}/>, []);

    return <MultiPageList
      itemBuilder={builder}
      loader={loader}
      deleteItemRef={deleteItemRef}>
    </MultiPageList>
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