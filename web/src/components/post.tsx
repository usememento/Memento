import {getAvatar, Post} from "../network/model.ts";
import {IconButton} from "./button.tsx";
import {
    MdFavorite,
    MdFavoriteBorder,
    MdOutlineComment,
    MdOutlineDelete,
    MdOutlineEdit
} from "react-icons/md";
import {useCallback, useState} from "react";
import {network} from "../network/network.ts";
import showMessage from "./message.tsx";
import app from "../app.ts";
import {Avatar} from "@nextui-org/react";

export default function PostWidget({post, showUser}: { post: Post, showUser?: boolean }) {


    const [state, setState] = useState({
        isLiked: post.isLiked,
        totalLiked: post.totalLiked,
        isLiking: false,
    });

    const likeOrUnlike = useCallback(() => {
        if (state.isLiking) return;
        setState(prev => ({...prev, isLiking: true}));
        if (state.isLiked) {
            network.unlikePost(post.postID).then(() => {
                setState(prev => ({...prev, isLiked: false, totalLiked: state.totalLiked - 1, isLiking: false}));
            }).catch((e) => {
                console.error("Failed to unlike post: ", e);
                showMessage({text: "Failed to unlike post"});
                setState(prev => ({...prev, isLiking: false}));
            });
        } else {
            network.likePost(post.postID).then(() => {
                setState(prev => ({...prev, isLiked: true, totalLiked: state.totalLiked + 1, isLiking: false}));
            }).catch((e) => {
                console.error("Failed to like post: ", e);
                showMessage({text: "Failed to like post"});
                setState(prev => ({...prev, isLiking: false}));
            });
        }
    }, [post.postID, state.isLiked, state.isLiking, state.totalLiked])

    const openComments = useCallback(() => {
    }, []);

    const openEdit = useCallback(() => {
    }, []);

    const deletePost = useCallback(() => {
    }, []);

    return <div className={"w-full flex flex-row border-b"}>
        {<>
            {showUser && <div className={"w-10 pt-4 pl-3"}>
                <Avatar src={getAvatar(post.user)} size={"sm"}></Avatar>
            </div>}
            <div className={"flex-grow"}>
                {showUser && <div className={"font-bold p-4"}>{post.user.nickname}</div>}
                {!showUser && <div className={"p-2"}></div>}
                <div className={"max-h-64 overflow-clip px-4 pb-2"}>{post.content}</div>
                <div className={"h-10 w-full flex flex-row px-2 items-center text-default-700"}>
                    <IconButton onPress={likeOrUnlike} primary={false} isLoading={state.isLiking}>
                        {state.isLiked ? <MdFavorite className={"text-red-500 dark:text-red-400"}/> :
                            <MdFavoriteBorder/>}
                    </IconButton>
                    <span className={"pl-1 text-sm"}>{state.totalLiked}</span>
                    <span className={"w-4"}></span>
                    <IconButton onPress={openComments} primary={false} isLoading={state.isLiking}>
                        <MdOutlineComment/>
                    </IconButton>
                    <span className={"pl-1 text-sm"}>{post.totalComment}</span>
                    <span className={"w-4"}></span>
                    <IconButton onPress={openEdit} primary={false} isLoading={state.isLiking}>
                        <MdOutlineEdit/>
                    </IconButton>
                    {post.user.username === app.user?.username && <>
                        <span className={"w-2"}></span>
                        <IconButton onPress={deletePost} primary={false} isLoading={state.isLiking}>
                            <MdOutlineDelete/>
                        </IconButton></>}
                    <span className={"flex-grow"}></span>
                    <span className={"text-sm text-default-600"}>{formatDate(new Date(post.editedAt))}</span>
                </div>
            </div>
        </>}
    </div>
}

function formatDate(date: Date) {
    return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()} ${date.getHours()}:${date.getMinutes()}`;
}