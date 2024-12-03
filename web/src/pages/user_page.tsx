import {useNavigate, useParams} from "react-router";
import {getAvatar, Post, User} from "../network/model.ts";
import {useCallback, useEffect, useRef, useState} from "react";
import {network} from "../network/network.ts";
import {Avatar, Spinner, Tab, Tabs} from "@nextui-org/react";
import Appbar from "../components/appbar.tsx";
import {Tr} from "../components/translate.tsx";
import showMessage from "../components/message.tsx";
import PostWidget from "../components/post.tsx";
import HeatMapWidget from "../components/heat_map.tsx";

export default function UserPage() {
    const {username} = useParams()

    const [user, setUser] = useState<User | null>(null)

    const userWidgetHeight = 80

    const [showTitle, setShowTitle] = useState(false)

    useEffect(() => {
        network.getUser(username!).then(setUser)

        const listener = () => {
            if (window.scrollY > userWidgetHeight)
                setShowTitle(true)
            else
                setShowTitle(false)
        };
        window.addEventListener("scroll", listener)
        return () => {
            window.removeEventListener("scroll", listener)
        }
    }, [username]);

    if (user == null) {
        return <div className={"w-full h-full flex items-center justify-center"}>
            <Spinner/>
        </div>
    }

    return <div className={"w-full h-full overflow-y-scroll"}>
        <Appbar title={user.username} hideTitle={!showTitle}/>
        <UserInfo user={user}/>
        <Pages user={user}/>
    </div>
}

function UserInfo({user}: { user: User }) {
    const navigate = useNavigate()

    return <div className={"px-4 py-2"}>
        <div className={"flex flex-row w-full items-center"}>
            <Avatar src={getAvatar(user)} className={"w-16 h-16"}/>
            <span className={"w-4"}/>
            <div>
                <p className={"font-bold text-xl pb-1"}>{user.username}</p>
                <p className={"text-sm"}>{`@${user.username}`}</p>
                <div className={"h-1"}/>
                <p>{user.bio}</p>
            </div>
        </div>
        <div className={"flex flex-row pt-4 text-sm"}>
            <div onClick={() => {
                navigate(`/user/${user.username}/follows`);
            }} className={"cursor-pointer"}><span className={"px-2 font-bold"}>{user.totalFollows}</span><Tr>Follows</Tr></div>
            <div className={"w-4"}/>
            <div onClick={() => {
                navigate(`/user/${user.username}/followers`);
            }} className={"cursor-pointer"}><span className={"px-2 font-bold"}>{user.totalFollower}</span><Tr>Followers</Tr></div>
        </div>
    </div>
}

function Pages({user}: {user: User}) {
    const pageNames = [
        "Posts",
        "Likes",
        "Statistics",
    ]

    const pages = [
        <Posts user={user}/>,
        <Likes user={user}/>,
        <Statistics user={user}/>,
    ]

    return <>
        <Tabs aria-label={"Options"} variant={"underlined"} color={"primary"} className={"w-full"} classNames={{
            tabList: "gap-6 w-full relative rounded-none border-b border-divider px-4 py-0",
            tab: "max-w-fit h-12 px-4",
            panel: "p-0 w-full"
        }}>
            {pageNames.map((name, index) => {
                return <Tab key={index} title={name}>
                    {pages[index]}
                </Tab>;
            })}
        </Tabs>
    </>
}

function Posts({user}: {user: User}) {
    const [state, setState] = useState({
        posts: [] as Post[],
        isLoading: false,
    });

    const isLoading = useRef(false);
    const pageRef = useRef(0);
    const maxPageRef = useRef(0);

    const loadPosts = useCallback(async () => {
        try {
            if (isLoading.current || pageRef.current > maxPageRef.current) return;
            isLoading.current = true;
            setState(prev => ({...prev, isLoading: true}));

            const [posts, maxPage] = await network.getPosts(user.username, pageRef.current);

            maxPageRef.current = maxPage as number;

            setState(prevState => ({
                posts: [...prevState.posts, ...(posts as Post[])],
                isLoading: false,
            }));

            pageRef.current += 1;
        }
        catch (e: any) {
            showMessage({text: e.toString()});
        } finally {
            isLoading.current = false;
        }
    }, [user.username]);

    useEffect(() => {
        loadPosts();

        const listener = () => {
            if (
                window.innerHeight + window.scrollY >= document.body.offsetHeight &&
                pageRef.current < maxPageRef.current &&
                !isLoading.current
            ) {
                loadPosts();
            }
        }

        window.addEventListener("scroll", listener);
        return () => window.removeEventListener("scroll", listener);
    }, [loadPosts]);

    return <div>
        {state.posts.map((post, index) => {
            return <PostWidget key={index} post={post} showUser={true}></PostWidget>
        })}
        {state.isLoading && <div className={"h-10 w-full flex flex-row items-center justify-center"}>
            <Spinner size={"md"}/>
        </div>}
    </div>
}

function Likes({user}: {user: User}) {
    const [state, setState] = useState({
        posts: [] as Post[],
        isLoading: false,
    });

    const isLoading = useRef(false);
    const pageRef = useRef(0);
    const maxPageRef = useRef(0);

    const loadPosts = useCallback(async () => {
        try {
            if (isLoading.current || pageRef.current > maxPageRef.current) return;
            isLoading.current = true;
            setState(prev => ({...prev, isLoading: true}));

            const [posts, maxPage] = await network.getUserLikes(user.username, pageRef.current);

            maxPageRef.current = maxPage as number;

            setState(prevState => ({
                posts: [...prevState.posts, ...(posts as Post[])],
                isLoading: false,
            }));

            pageRef.current += 1;
        }
        catch (e: any) {
            showMessage({text: e.toString()});
        } finally {
            isLoading.current = false;
        }
    }, [user.username]);

    useEffect(() => {
        loadPosts();

        const listener = () => {
            if (
                window.innerHeight + window.scrollY >= document.body.offsetHeight &&
                pageRef.current < maxPageRef.current &&
                !isLoading.current
            ) {
                loadPosts();
            }
        }

        window.addEventListener("scroll", listener);
        return () => window.removeEventListener("scroll", listener);
    }, [loadPosts]);

    return <div>
        {state.posts.map((post, index) => {
            return <PostWidget key={index} post={post} showUser={true}></PostWidget>
        })}
        {state.isLoading && <div className={"h-10 w-full flex flex-row items-center justify-center"}>
            <Spinner size={"md"}/>
        </div>}
    </div>
}

function Statistics({user}: {user: User}) {
    return <div>
        <div className={"px-2"} style={{
            maxWidth: "832px"
        }}>
            <HeatMapWidget username={user.username} showStatistics={false}/>
        </div>
        <div className={"px-4 py-2"}>
            <p><Tr>Register At</Tr></p>
            <div className={"h-1"}/>
            <p className={"text-sm text-default-700"}>{new Date(user.registeredAt).toLocaleString()}</p>
        </div>
        <div className={"px-4 py-2"}>
            <p><Tr>Total Posts</Tr></p>
            <div className={"h-1"}/>
            <p className={"text-sm text-default-700"}>{user.totalPosts}</p>
        </div>
        <div className={"px-4 py-2"}>
            <p><Tr>Total Likes</Tr></p>
            <div className={"h-1"}/>
            <p className={"text-sm text-default-700"}>{user.totalLiked}</p>
        </div>
        <div className={"px-4 py-2"}>
            <p><Tr>Total comments</Tr></p>
            <div className={"h-1"}/>
            <p className={"text-sm text-default-700"}>{user.totalComment}</p>
        </div>
    </div>
}