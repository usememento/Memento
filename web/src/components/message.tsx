import {createContext, ReactNode} from "react";
import {createRoot} from "react-dom/client";
import {TapRegion} from "./button.tsx";
import {MdClose} from "react-icons/md";

export default function showMessage({text}:{ text: string }) {
    const div = document.createElement("div");
    div.className = "fixed left-0 right-0 bottom-4 flex items-center justify-center";
    div.innerHTML = `
        <div class="w-full h-12 bg-default-800 text-white p-4 rounded-md shadow-lg max-w-sm flex items-center justify-center animate-appearance-in">
            <div class="flex-grow">${text}</div>
        </div>
    `;
    document.body.appendChild(div);
    setTimeout(() => {
        div.remove();
    }, 3000);
}

export const dialogCanceler = createContext(() => {})

export function showDialog({children, title}: {children: ReactNode, title: string}) {
    return new Promise<null>((resolve) => {
        const div = document.createElement("div");
        div.className = "fixed left-0 right-0 top-0 bottom-0 flex items-center justify-center z-50 bg-black bg-opacity-50";
        document.body.appendChild(div);
        createRoot(div).render(<div className={"bg-background w-full max-w-sm p-4 shadow-md items-center justify-center rounded-md animate-appearance-in"}>
            <div className={"w-full h-10 flex flex-row items-center"}>
                <TapRegion borderRadius={24} onPress={() => {
                    resolve(null);
                    div.remove();
                }}>
                    <div className={"p-2 flex items-center justify-center"}>
                        <MdClose size={24}></MdClose>
                    </div>
                </TapRegion>
                <div className={"flex-grow ml-3"}>{title}</div>
            </div>
            <dialogCanceler.Provider value={() => {
                resolve(null);
                div.remove();
            }}>
                {children}
            </dialogCanceler.Provider>
        </div>);
    });
}