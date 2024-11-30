import {useCallback, useContext, useState} from "react";
import {Post} from "../network/model.ts";
import showMessage, {dialogCanceler} from "../components/message.tsx";
import {network} from "../network/network.ts";
import app from "../app.ts";
import {IconButton, TapRegion} from "../components/button.tsx";
import {MdLock, MdOutlineImage, MdOutlineInfo, MdPublic} from "react-icons/md";
import {Tr} from "../components/translate.tsx";
import {Button, Spinner} from "@nextui-org/react";

export default function PostEditPage({post, onEdited}: { post: Post, onEdited: (p: Post) => void}) {
    const [state, setState] = useState({
        text: post.content,
        isPublic: !post.isPrivate,
    });

    const [isSubmitting, setIsSubmitting] = useState(false);

    const canceler = useContext(dialogCanceler);

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
                setState(prev => ({
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

    const submit = useCallback(async () => {
        setIsSubmitting(true);
        try {
            await network.editPost(post.postID, state.text, state.isPublic);
            showMessage({text: "Post updated"});
            canceler();
            onEdited({...post, content: state.text, isPrivate: !state.isPublic});
        } catch (e: any) {
            showMessage({text: e.toString()});
        }
        setIsSubmitting(false);
    }, [canceler, onEdited, post, state.isPublic, state.text]);

    return <div className={"w-full h-full"}>
        <textarea className={"w-full p-4 focus:outline-none resize-none"} value={state.text} onChange={(e) => {
            setState(prev => ({...prev, text: e.target.value}));
        }} style={{
            height: "calc(100% - 32px)",
        }}></textarea>
        <div className={"h-8 w-full flex flex-row"}>
            <TapRegion onPress={() => {
                setState({...state, isPublic: !state.isPublic});
            }} borderRadius={12}>
                <div className={"h-8 flex flex-row items-center justify-center text-primary text-sm px-2"}>
                    {state.isPublic ? <MdPublic size={18}/> : <MdLock size={18}/>}
                    <span className={"w-2"}></span>
                    <Tr>{state.isPublic ? "Public" : "Private"}</Tr>
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
            <Button className={"h-8 rounded-2xl"} color={"primary"} onClick={submit}>{isSubmitting ? <Spinner color={"default"} size={"sm"}></Spinner> : <Tr>Post</Tr>}</Button>
        </div>
    </div>
}