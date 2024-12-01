import {useLocation, useNavigate, useParams} from "react-router";
import {MarkdownWidget, PopUpWindow} from "../components/post.tsx";
import {useCallback, useEffect, useState} from "react";
import {getAvatar, Post} from "../network/model.ts";
import {Avatar, Spinner} from "@nextui-org/react";
import {network} from "../network/network.ts";
import {IconButton, TapRegion} from "../components/button.tsx";
import {MdArrowBack, MdFavorite, MdFavoriteBorder, MdOutlineComment, MdShare} from "react-icons/md";
import showMessage from "../components/message.tsx";
import {translate} from "../components/translate.tsx";
import CommentsPage from "./comments_page.tsx";

export default function PostPage() {
    const { id } = useParams();
    
    const location = useLocation();

    const [post, setPost] = useState<Post | null>(location.state?.post);

    useEffect(() => {
        if(!post) {
            network.getPost(id!).then(setPost);
        }
    }, [id, post]);

    const navigate = useNavigate();
    
    const [state, setState] = useState({
        isLiked: false,
        totalLiked: 0,
        isLiking: false,
    })

    const likeOrUnlike = useCallback(() => {
        if (state.isLiking) return;
        setState(prev => ({...prev, isLiking: true}));
        const pid = Number(id);
        if (state.isLiked) {
            network.unlikePost(pid).then(() => {
                setState(prev => ({...prev, isLiked: false, totalLiked: state.totalLiked - 1, isLiking: false}));
            }).catch((e) => {
                console.error("Failed to unlike post: ", e);
                showMessage({text: "Failed to unlike post"});
                setState(prev => ({...prev, isLiking: false}));
            });
        } else {
            network.likePost(pid).then(() => {
                setState(prev => ({...prev, isLiked: true, totalLiked: state.totalLiked + 1, isLiking: false}));
            }).catch((e) => {
                console.error("Failed to like post: ", e);
                showMessage({text: "Failed to like post"});
                setState(prev => ({...prev, isLiking: false}));
            });
        }
    }, [id, state.isLiked, state.isLiking, state.totalLiked])

    const [showComments, setShowComments] = useState(false);

    const openComments = useCallback(() => {
        console.log("Open comments");
        setShowComments(prevState => !prevState);
    }, []);

    return <div className={"w-full h-full overflow-y-scroll"}>
        {showComments &&
          <div className={"fixed z-20 left-0 top-0 bottom-0 right-0 flex items-center justify-center " +
              "bg-primary-50 backdrop-blur bg-opacity-20 animate-appearance-in"} onClick={openComments}>
            <PopUpWindow title={translate("Comments")} onBack={openComments}>
              <CommentsPage postId={Number(id)}></CommentsPage>
            </PopUpWindow>
          </div>}
        <div className={"h-12 sticky w-full flex flex-row px-2 items-center text-xl top-0 bg-background"}>
            <TapRegion onPress={() => {
                navigate(-1);
            }} borderRadius={9999}>
                <div
                    className={`w-10 h-10 flex flex-row items-center justify-center text-2xl`}>
                    <MdArrowBack/>
                </div>
            </TapRegion>
            <span className={"w-2"}/>
            {post ? <>
                <TapRegion onPress={() => {
                    navigate(`/user/${post.user.username}`);
                }} borderRadius={8}>
                    <div className={"h-8 flex flex-row items-center px-2"}>
                        <Avatar src={getAvatar(post.user)} className={"w-6 h-6"}/>
                        <span className={"text-sm ml-2"}>{post.user.nickname}</span>
                    </div>
                </TapRegion>
                <div className={"flex-grow"}></div>
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
                <IconButton onPress={() => {
                    navigator.share({
                        url: window.location.href,
                    });
                }} primary={false}>
                    <MdShare/>
                </IconButton>
            </> : "Post"}
        </div>
        <div className={"w-full select-text px-4"} style={{
            height: "calc(100vh - 56px)",
        }}>
            {post
                ? <MarkdownWidget content={post.content}/>
                : <div className={"flex items-center justify-center w-full h-full"}><Spinner/></div>}
        </div>
    </div>
}