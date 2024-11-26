import tr from "../assets/translation.json";
import app from "../app.ts";

export function Tr({children}: {children: string}) {
    return <span>{translate(children)}</span>
}

export function translate(key: string) : string{
    return (tr as any)[app.locale][key] || key;
}