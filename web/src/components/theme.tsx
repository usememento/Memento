import {useEffect, useState} from "react";

export default function Theme({children}: {children: any}) {
    const [dark, setDark] = useState(window.matchMedia('(prefers-color-scheme: dark)').matches);

    useEffect(() => {
        const listener = (e: MediaQueryListEvent) => {
            setDark(e.matches);
        }
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', listener);
        return () => {
            window.matchMedia('(prefers-color-scheme: dark)').removeEventListener('change', listener);
        }
    }, []);

    return <div className={`w-full h-full ${dark ? "dark" : ""} text-foreground bg-background`}>
        {children}
    </div>
}