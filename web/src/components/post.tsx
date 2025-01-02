import {getAvatar, Post} from "../network/model.ts";
import {IconButton, TapRegion} from "./button.tsx";
import {
    MdCopyAll,
    MdFavorite,
    MdFavoriteBorder,
    MdOutlineComment,
    MdOutlineDelete,
    MdOutlineEdit
} from "react-icons/md";
import {ReactNode, useCallback, useContext, useEffect, useRef, useState} from "react";
import {network} from "../network/network.ts";
import showMessage, {dialogCanceler, showDialog} from "./message.tsx";
import app from "../app.ts";
import {Avatar, Button} from "@nextui-org/react";
import {Tr, translate} from "./translate.tsx";
import CommentsPage from "../pages/comments_page.tsx";
import Appbar from "./appbar.tsx";
import Markdown from "react-markdown";
import remarkGfm from 'remark-gfm';
import "../markdown.css";
import {useNavigate} from "react-router";

const hljs = import('highlight.js/lib/common');
const dart = import('highlight.js/lib/languages/dart');

export default function PostWidget({post, showUser, onDelete}: {
    post: Post,
    showUser?: boolean,
    onDelete?: () => void
}) {
    const [state, setState] = useState({
        content: post.content,
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

    const navigate = useNavigate();

    const openEdit = useCallback(() => {
        navigate(`/post/${post.postID}/edit`, {state: {post}});
    }, [navigate, post]);

    const deletePost = useCallback(() => {
        showDialog({
            title: translate("Delete post"),
            children: <DeletePostDialog postId={post.postID} onDelete={onDelete!}/>
        })
    }, [onDelete, post.postID]);

    return <TapRegion className={"w-full"} lighter={true} onPress={() => {
        navigate(`/post/${post.postID}`, {state: {post}});
    }}>
        <div className={"w-full flex flex-row border-b"}>
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
                    <div className={"max-h-64 overflow-clip px-4 pb-2 select"}>
                        <MarkdownWidget content={state.content} limitHeight={true}/>
                    </div>
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
    </TapRegion>
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

export function PopUpWindow({children, title, onBack}: { children: ReactNode, title: string, onBack: () => void }) {
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

function DeletePostDialog({postId, onDelete}: { postId: number, onDelete: () => void }) {
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
    }, [canceler, onDelete, postId]);
    
    return <div className={"py-2"}>
        <p><Tr>Are you sure you want to delete this post?</Tr></p>
        <div className={"flex flex-row-reverse mt-4"}>
            <Button color={"danger"} onClick={deletePost} isLoading={isDeleting} className={"h-8 rounded-2xl"}><Tr>Delete</Tr></Button>
        </div>
    </div>
}

export function MarkdownWidget({content, limitHeight}: {content: string, limitHeight?: boolean}) {
    const ref = useRef<HTMLDivElement | null>(null);

    const navigate = useNavigate();

    useEffect(() => {
        if (ref.current)
            renderTags(ref.current, navigate);
    }, [navigate]);

    if(limitHeight) {
        const lines = content.split("\n");
        if(lines.length > 20) {
            content = lines.slice(0, 20).join("\n");
        }
    }

    return <div ref={ref}>
        <Markdown remarkPlugins={[remarkGfm]} className={`${limitHeight ? "max-h-56" : ""} markdown`} components={{
            pre(props) {
                return <CodeWidget props={props}/>
            },
            input(props) {
                return <input {...props} disabled={false}/>
            }
        }}>{content}</Markdown>
    </div>
}

function CodeWidget({props}: {props: any}) {
    const {children, className, ...rest} = props;
    const match = /language-(\w+)/.exec(children?.props?.className || '');

    const ref = useRef<HTMLElement>();

    useEffect(() => {
        if(ref.current)
            hljs.then((e) => {
                dart.then((d) => {
                    e.default.registerLanguage('dart', d.default);
                    e.default.highlightElement(ref.current!);
                })
            })
    }, []);

    return <div className={"bg-content2 rounded-lg bg-opacity-60 my-2"}>
        <div className={"h-9 flex flex-row items-center px-4 border-b"}>
            <span>{match ? match[1] : "code"}</span>
            <span className={"flex-grow"}></span>
            <TapRegion onPress={() => {
                navigator.clipboard.writeText(children?.props?.children);
                showMessage({text: translate("Copied")});
            }} borderRadius={8}>
                <div className={"h-8 flex flex-row items-center px-1 select-none"}>
                    <MdCopyAll/>
                    <span className={"pl-1"}>Copy</span>
                </div>
            </TapRegion>
        </div>
        <div className={"px-2"}>
            <pre {...rest} className={className} ref={ref}>
                {children}
            </pre>
        </div>
    </div>;
}

function renderTags(container: HTMLElement, navigate: (value: string) => void) {
    for (const p of container.querySelectorAll('p')) {
        if (p.textContent == null || !p.textContent.includes('#')) {
            continue;
        }
        const children = p.childNodes;
        const newChildren = [];
        for(let i=0; i < children.length; i++) {
            if (children[i].nodeType == Node.TEXT_NODE) {
                const text = children[i].textContent;
                if (text == null || !text.includes('#')) {
                    newChildren.push(children[i]);
                    continue;
                }
                const split = text!.split(" ");
                let buffer = "";
                for (let j = 0; j < split.length; j++) {
                    if (split[j].startsWith("#") && split[j].length > 1) {
                        if (buffer.length > 0) {
                            newChildren.push(document.createTextNode(buffer));
                        }
                        const a = document.createElement('span');
                        a.className = "text-primary cursor-pointer";
                        a.textContent = split[j];
                        a.onclick = (e) => {
                            e.stopPropagation();
                            navigate(`/tag/${split[j].substring(1)}`);
                        };
                        newChildren.push(a);
                        buffer = " ";
                    } else {
                        buffer += split[j] + " ";
                    }
                }
                if (buffer.length > 0) {
                    newChildren.push(document.createTextNode(buffer));
                }
            } else {
                newChildren.push(children[i]);
            }
        }
        p.innerHTML = "";
        for (const c of newChildren) {
            p.appendChild(c);
        }
    }
}