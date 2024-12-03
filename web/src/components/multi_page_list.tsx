import React, {useCallback, useEffect} from "react";
import showMessage from "./message.tsx";
import {Spinner} from "@nextui-org/react";

export default function MultiPageList<T>({itemBuilder, loader}: {
    itemBuilder: (item: T) => React.ReactNode, 
    loader: (page: number) => Promise<[T[], number]>}) {
    const [state, setState] = React.useState({
        items: [] as T[],
        loading: false,
    })
    
    const pageRef = React.useRef(0);
    const maxPageRef = React.useRef(0);
    const isLoading = React.useRef(false);

    const loadMore = useCallback(async () => {
        try {
            if (isLoading.current || pageRef.current > maxPageRef.current) return;
            isLoading.current = true;
            setState(prev => ({...prev, loading: true}));

            const [items, maxPage] = await loader(pageRef.current);

            maxPageRef.current = maxPage as number;

            setState(prevState => ({
                items: [...prevState.items, ...(items as T[])],
                loading: false,
            }));

            pageRef.current += 1;
        }
        catch (e: any) {
            console.error(e);
            showMessage({text: e.toString()});
        } finally {
            isLoading.current = false;
        }
    }, [loader])

    useEffect(() => {
        loadMore();

        const listener = () => {
            if (
                window.innerHeight + window.scrollY >= document.body.offsetHeight &&
                pageRef.current < maxPageRef.current &&
                !isLoading.current
            ) {
                loadMore();
            }
        }

        window.addEventListener("scroll", listener);
        return () => window.removeEventListener("scroll", listener);
    }, [loadMore]);

    return <div>
        {state.items.map((e, index) => <div key={index}>{itemBuilder(e)}</div>)}
        {state.loading && <div className={"text-center text-accent-foreground"}><Spinner/></div>}
    </div>
}