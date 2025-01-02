import {useCallback, useRef} from "react";
import {Post} from "../network/model.ts";
import {network} from "../network/network.ts";
import Editor, {EditorData} from "../components/editor.tsx";
import {useLocation, useNavigate} from "react-router";
import Appbar from "../components/appbar.tsx";
import {translate} from "../components/translate.tsx";

export default function PostEditPage() {
    const location = useLocation();

    if (!location.state?.post) {
        window.location.href = "/";
    }
    
    const post = location.state?.post as Post;
    
    const navigate = useNavigate();

    const value = useRef({
        text: post.content,
        isPublic: !post.isPrivate,
    })

    const submit = useCallback(async () => {
        if(value.current.text.trim().length === 0) {
            throw "Post cannot be empty";
        }
        await network.editPost(post.postID, value.current.text, value.current.isPublic);
        navigate("-1");
    }, [navigate, post.postID]);

    const onChanged = useCallback((data: EditorData) => {
        value.current = {
            text: data.text,
            isPublic: data.isPublic,
        };
    }, []);

    return <div className={"w-full h-full"}>
        <Appbar title={translate("Edit")}/>
        <div className={"w-full"} style={{
            height: "calc(100% - 48px)",
        }}>
            <Editor onChanged={onChanged} submit={submit} fullHeight={true} initialText={value.current.text} isPublic={value.current.isPublic}/>
        </div>
    </div>
}