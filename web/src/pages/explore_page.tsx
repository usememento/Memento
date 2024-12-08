import {useEffect, useState} from "react";
import {network} from "../network/network.ts";
import {Loading} from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import SearchBar from "../components/search.tsx";
import {TapRegion} from "../components/button.tsx";
import {Tr} from "../components/translate.tsx";
import {useNavigate} from "react-router";
import MultiPageList from "../components/multi_page_list.tsx";

export default function ExplorePage() {
    const [showSidebar, setShowSidebar] = useState(window.innerWidth > 768);

    useEffect(() => {
        const listener = () => {
            setShowSidebar(window.innerWidth > 768);
        };
        window.addEventListener("resize", listener);
        return () => window.removeEventListener("resize", listener);
    }, []);

    return <div className={"flex flex-row w-full h-full"}>
        <div className={"overflow-y-scroll h-full flex-grow"}>
            <UserPosts></UserPosts>
        </div>
        {showSidebar && <div className={"w-64 h-full border-l flex-shrink-0"}>
            <SearchBar />
            <div className={"h-4"}></div>
            <TagList/>
        </div>}
    </div>
}

function UserPosts() {
    return <MultiPageList itemBuilder={(i) => <PostWidget post={i}/>} loader={network.getAllPosts}></MultiPageList>
}

function TagList() {
    const [tags, setTags] = useState<string[] | null>(null);

    const navigate = useNavigate();

    useEffect(() => {
        network.getTags(true).then(setTags);
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