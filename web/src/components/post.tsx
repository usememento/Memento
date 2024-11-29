import {getAvatar, Post} from "../network/model.ts";
import {IconButton} from "./button.tsx";
import {
    MdFavorite,
    MdFavoriteBorder,
    MdOutlineComment,
    MdOutlineDelete,
    MdOutlineEdit
} from "react-icons/md";
import {ReactNode, useCallback, useContext, useEffect, useState} from "react";
import {network} from "../network/network.ts";
import showMessage, {dialogCanceler, showDialog} from "./message.tsx";
import app from "../app.ts";
import {Avatar, Button} from "@nextui-org/react";
import {Tr, translate} from "./translate.tsx";
import CommentsPage from "../pages/comments_page.tsx";
import Appbar from "./appbar.tsx";

export default function PostWidget({post, showUser, onDelete}: {
    post: Post,
    showUser?: boolean,
    onDelete?: () => void
}) {
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

    const [showComments, setShowComments] = useState(false);

    const openComments = useCallback(() => {
        console.log("Open comments");
        setShowComments(prevState => !prevState);
    }, []);

    const openEdit = useCallback(() => {
    }, []);

    const deletePost = useCallback(() => {
        showDialog({
            title: translate("Delete post"),
            children: <DeletePostDialog postId={post.postID} onDelete={onDelete!}/>
        })
    }, [post.postID]);

    return <div className={"w-full flex flex-row border-b"}>
        {<>
            {showComments &&
                <div className={"fixed z-20 left-0 top-0 bottom-0 right-0 flex items-center justify-center " +
                    "bg-primary-50 backdrop-blur bg-opacity-20 animate-appearance-in"} onClick={openComments}>
                    <PopUpWindow title={translate("Comments")} onBack={openComments}>
                        <CommentsPage postId={post.postID}></CommentsPage>
                    </PopUpWindow>
                </div>}
            {showUser && <div className={"w-10 pt-4 pl-3"}>
                <Avatar src={getAvatar(post.user)} size={"sm"}></Avatar>
            </div>}
            <div className={"flex-grow"}>
                {showUser && <div className={"font-bold p-4"}>{post.user.nickname}</div>}
                {!showUser && <div className={"p-2"}></div>}
                <div className={"max-h-64 overflow-clip px-4 pb-2 select"}>{post.content}</div>
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
                    {post.user.username === app.user?.username && <>
                        <span className={"w-4"}></span>
                        <IconButton onPress={openEdit} primary={false} isLoading={state.isLiking}>
                            <MdOutlineEdit/>
                        </IconButton>
                        {onDelete && <><span className={"w-2"}></span>
                            <IconButton onPress={deletePost} primary={false} isLoading={state.isLiking}>
                                <MdOutlineDelete/>
                            </IconButton></>}</>}
                    <span className={"flex-grow"}></span>
                    <span className={"text-sm text-default-600"}>{formatDate(new Date(post.editedAt))}</span>
                </div>
            </div>
        </>}
    </div>
}

function formatDate(date: Date) {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    if (diff < 60 * 1000) {
        return translate("Just now");
    } else if (diff < 60 * 60 * 1000) {
        switch (app.locale) {
            case "zh-CN":
                return `${Math.floor(diff / 1000 / 60)}分钟前`;
            case "zh-TW":
                return `${Math.floor(diff / 1000 / 60)}分鐘前`;
            default:
                return `${Math.floor(diff / 1000 / 60)}m ago`;
        }
    } else if (diff < 24 * 60 * 60 * 1000) {
        switch (app.locale) {
            case "zh-CN":
                return `${Math.floor(diff / 1000 / 60 / 60)}小时前`;
            case "zh-TW":
                return `${Math.floor(diff / 1000 / 60 / 60)}小時前`;
            default:
                return `${Math.floor(diff / 1000 / 60 / 60)}h ago`;
        }
    } else if (now.getFullYear() === date.getFullYear()) {
        return `${date.getMonth() + 1}-${date.getDate()}`;
    } else {
        return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
    }
}

function PopUpWindow({children, title, onBack}: { children: ReactNode, title: string, onBack: () => void }) {
    const [showPopUp, setShowPopUp] = useState(window.innerWidth > 600);

    useEffect(() => {
        const listener = () => {
            setShowPopUp(window.innerWidth > 600);
        }

        window.addEventListener("resize", listener);
        return () => window.removeEventListener("resize", listener);
    }, []);

    return <div className={`${showPopUp ? "shadow-md rounded-xl" : ""} w-full bg-background flex flex-col`}
                onClick={(e) => {
                    e.stopPropagation();
                }} style={{
        height: showPopUp ? "calc(100% - 4rem)" : "100%",
        maxWidth: showPopUp ? "420px" : undefined,
    }}>
        <Appbar title={title} onBack={onBack}/>
        <div className={"w-full"} style={{
            height: "calc(100% - 3rem)",
        }}>
            {children}
        </div>
    </div>
}

function DeletePostDialog({postId, onDelete}: {postId: number, onDelete: () => void}) {
    const [isDeleting, setIsDeleting] = useState(false);

    const canceler = useContext(dialogCanceler);
    
    const deletePost = useCallback(() => {
        setIsDeleting(true);
        network.deletePost(postId).then(() => {
            setIsDeleting(false);
            showMessage({text: translate("Post deleted")});
            canceler();
            onDelete();
        }).catch((e) => {
            console.error("Failed to delete post: ", e);
            showMessage({text: translate("Failed to delete post")});
            setIsDeleting(false);
        });
    }, [canceler, postId]);
    
    return <div className={"py-2"}>
        <p><Tr>Are you sure you want to delete this post?</Tr></p>
        <div className={"flex flex-row-reverse mt-4"}>
            <Button color={"danger"} onClick={deletePost} isLoading={isDeleting} className={"h-8 rounded-2xl"}><Tr>Delete</Tr></Button>
        </div>
    </div>
}