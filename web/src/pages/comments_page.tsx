import {useCallback, useEffect, useRef, useState} from "react";
import showMessage from "../components/message.tsx";
import {network} from "../network/network.ts";
import {Avatar, Spinner} from "@nextui-org/react";
import {Comment, getAvatar} from "../network/model.ts";
import {IconButton} from "../components/button.tsx";
import {MdFavorite, MdFavoriteBorder, MdSend} from "react-icons/md";

export default function CommentsPage({postId}: { postId: number }) {
    const [state, setState] = useState({
        comments: null as (Comment[] | null),
        isLoading: true,
    })

    const isLoading = useRef(false);
    const pageRef = useRef(0);
    const maxPageRef = useRef(0);
    
    const loadComments = useCallback(async () => {
        try {
            if (isLoading.current || pageRef.current > maxPageRef.current) return;
            isLoading.current = true;
            setState(prev => ({...prev, isLoading: true}));
            
            const [comments, maxPage] = await network.getComments(postId, pageRef.current);
            
            maxPageRef.current = maxPage as number;
            
            setState(prevState => ({
                comments: [...(prevState.comments ?? []), ...(comments as Comment[])],
                isLoading: false,
            }));
            
            pageRef.current += 1;
        } catch (e: any) {
            showMessage({text: e.toString()});
        } finally {
            isLoading.current = false;
        }
    }, [postId]);

    const onCreate = useCallback(() => {
        isLoading.current = false;
        pageRef.current = 0;
        maxPageRef.current = 0;
        setState({comments: null, isLoading: true});
        loadComments();
    }, [loadComments]);

    useEffect(() => {
        loadComments();
        
        const listener = () => {
            if (
                window.innerHeight + window.scrollY >= document.body.offsetHeight &&
                pageRef.current < maxPageRef.current &&
                !isLoading.current
            ) {
                loadComments();
            }
        }
        
        window.addEventListener("scroll", listener);
        return () => window.removeEventListener("scroll", listener);
    }, [loadComments]);
    
    return <div className={"flex flex-col w-full h-full overflow-hidden"}>
        <div className={"w-full flex-grow overflow-y-auto"}>
            {state.comments == null && <div className={"w-full h-full flex justify-center items-center"}>
                <Spinner/>
            </div>}
            {state.comments?.map((comment, index) => {
                return <CommentWidget key={index} comment={comment}></CommentWidget>
            })}
            {state.isLoading && state.comments != null && <div className={"w-full h-10 flex justify-center items-center"}>
                <Spinner/>
            </div>}
        </div>
        <CommentSendBar id={postId} onCreate={onCreate}></CommentSendBar>
    </div>
}

function CommentWidget({comment}: { comment: Comment }) {
    const [state, setState] = useState({
        isLiked: comment.isLiked,
        isLiking: false,
        likes: comment.liked,
    })
    
    const likeOrUnlike = useCallback(async () => {
        setState(prev => ({...prev, isLiking: true}));
        
        try {
            if (state.isLiked) {
                await network.unlikeComment(comment.commentId);
            } else {
                await network.likeComment(comment.commentId);
            }
            setState(prev => ({
                isLiked: !prev.isLiked,
                isLiking: false,
                likes: prev.isLiked ? prev.likes - 1 : prev.likes + 1,
            }));
        } catch (e: any) {
            showMessage({text: e.toString()});
            setState(prev => ({...prev, isLiking: false}));
        }
    }, [comment.commentId, state.isLiked])

    return <div className={"w-full p-4 border-b border-content2"}>
        <div className={"flex flex-row items-center"}>
            <Avatar src={getAvatar(comment.user)} size={"sm"}/>
            <div className={"ml-2"}>
                <div className={"text-sm font-semibold"}>{comment.user.nickname}</div>
                <div className={"text-xs text-default-700"}>{(new Date(comment.createdAt).toLocaleString())}</div>
            </div>
            <div className={"flex-grow"}></div>
            <IconButton onPress={likeOrUnlike} primary={state.isLiked} isLoading={state.isLiking}>
                {state.isLiked ? <MdFavorite  className={"text-red-500 dark:text-red-400"}/> : <MdFavoriteBorder/>}
            </IconButton>
            <span className={"text-sm ml-1"}>{state.likes}</span>
        </div>
        <div className={"mt-2 text-sm px-2"}>{comment.content}</div>
    </div>
}

function CommentSendBar({id, onCreate}: { id: number, onCreate: () => void }) {
    const [text, setText] = useState("");
    
    const [isSending, setIsSending] = useState(false);
    
    const sendComment = useCallback(async () => {
        setIsSending(true);
        
        try {
            await network.sendComment(id, text);
            setText("");
            onCreate();
        } catch (e: any) {
            showMessage({text: e.toString()});
        } finally {
            setIsSending(false);
        }
    }, [id, onCreate, text]);

    return <form onSubmit={(e) => {
        e.preventDefault();
        sendComment();
    }}>
        <div className={"flex flex-row items-center mx-2 px-2 my-2 bg-default-100 rounded-md"}>
            <input onChange={(e) => {
                setText(e.target.value);
            }} value={text} type={"text"} placeholder={"Write a comment..."}
                   className={"w-full p-2 focus:outline-none"}/>
            <IconButton onPress={sendComment} isLoading={isSending}>
                <MdSend/>
            </IconButton>
        </div>
    </form>
}