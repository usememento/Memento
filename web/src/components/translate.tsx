import tr from "../assets/translation.json";
import app from "../app.ts";

export function Tr({children}: {children: string}) {
    return <span>{translate(children)}</span>
}

export function translate(key: string) : string{
    let locale=app.locale
    if(!["zh-CN","zh-TW","en-US"].includes(locale)){
        locale="en-US"
    }
    return (tr as any)[locale][key] || key;
}