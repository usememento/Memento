import { useIntersectionObserver } from "@uidotdev/usehooks";
import {Post} from "../network/model.ts";

export default function PostWidget({post}: {post: Post}) {
    const [ref, entry] = useIntersectionObserver();

    return <div ref={ref} className={"w-full"}>
        {entry?.isIntersecting && <>
            <div className={"max-h-64 overflow-clip"}>{post.content}</div>
            <div className={"h-8 w-full"}></div>
        </>}
    </div>
}