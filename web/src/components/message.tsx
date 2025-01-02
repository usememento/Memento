import {createContext, ReactNode, useContext, useState} from "react";
import {createRoot} from "react-dom/client";
import {TapRegion} from "./button.tsx";
import {MdClose} from "react-icons/md";
import {Button, Input} from "@nextui-org/react";
import {Tr} from "./translate.tsx";
import Theme from "./theme.tsx";

export default function showMessage({text}:{ text: string }) {
    const div = document.createElement("div");
    div.className = "fixed left-0 right-0 bottom-4 flex items-center justify-center z-50";
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

export function showDialog({children, title, fullscreen}: {children: ReactNode, title?: string, fullscreen?: boolean}) {
    return new Promise<null>((resolve) => {
        const div = document.createElement("div");
        document.body.appendChild(div);
        createRoot(div).render(<Theme>
            <div onDrag={() => {
            }} onPointerDown={(e) => {
                console.log(e);
                div.remove();
                resolve(null);
            }}
                 className={"fixed left-0 right-0 top-0 bottom-0 flex items-center justify-center z-50 bg-black bg-opacity-50 animate-opacity-in"}>
                <div onPointerDown={(e) => {
                    e.stopPropagation();
                }}
                     className={`bg-background w-full ${(fullscreen ?? false ? "h-full" : "max-w-sm shadow-md rounded-md")} px-2 py-2 items-center justify-center animate-appearance-in dark:border`}>
                    {title && <div className={"w-full h-9 flex flex-row items-center"}>
                      <TapRegion borderRadius={24} onPress={() => {
                          resolve(null);
                          div.remove();
                      }}>
                        <div className={"p-2 flex items-center justify-center"}>
                          <MdClose size={24}></MdClose>
                        </div>
                      </TapRegion>
                      <div className={"flex-grow ml-3"}>{title}</div>
                    </div>}
                    <dialogCanceler.Provider value={() => {
                        resolve(null);
                        div.remove();
                    }}>
                        {children}
                    </dialogCanceler.Provider>
                </div>
            </div>
        </Theme>);
    });
}

export function showLoadingDialog() {
    const div = document.createElement("div");
    div.className = "fixed left-0 right-0 top-0 bottom-0 flex items-center justify-center z-50 bg-opacity-50 bg-black";
    document.body.appendChild(div);
    div.innerHTML = `
        <div class="w-44 h-16 bg-background rounded-2xl flex items-center justify-center shadow">
            <svg aria-hidden="true" class="w-8 h-8 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600"
                viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path
                    d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                    fill="currentColor"/>
                <path
                    d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                    fill="currentFill"/>
            </svg>
            <span class="pl-4">Loading</span>
        </div>
    `;

    return () => {
        div.remove();
    };
}

export function Loading({size}: {size?: number}) {
    return <svg aria-hidden="true" className="bg-opacity-0 animate-spin fill-primary text-content2" style={{width: size ?? 24, height: size ?? 24}}
                viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path
            d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
            fill="currentColor"/>
        <path
            d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
            fill="currentFill"/>
    </svg>;
}

export function showInputDialog(title: string, fieldName: string, onFinished: (value: string) => void, initialValue?: string) {
    return showDialog({
        title: title,
        children: <InputDialog onSubmit={onFinished} fieldName={fieldName} initialValue={initialValue}/>,
    })
}

function InputDialog({onSubmit, fieldName, initialValue}: {onSubmit: (value: string) => (void | Promise<void>), fieldName: string, initialValue?: string}) {
    const canceler = useContext(dialogCanceler);

    const [isSubmitting, setIsSubmitting] = useState(false);

    return <form className={"px-2"} onSubmit={(e) => {
        e.preventDefault();
        const value = (document.getElementById('input') as HTMLInputElement).value;
        const res = onSubmit(value);
        if (res instanceof Promise) {
            setIsSubmitting(true);
            res.then(() => {
                canceler();
            }).catch((e: any) => {
                showMessage({text: e.toString()});
                setIsSubmitting(false);
            });
        } else {
            canceler();
        }
    }}>
        <Input type={"text"} id={'input'} placeholder={fieldName} className={"my-2"} defaultValue={initialValue}/>
        <div className={"w-full h-12 flex flex-row-reverse mt-2"}>
            <Button isLoading={isSubmitting} type={"submit"} color={"primary"}><Tr>Submit</Tr></Button>
        </div>
    </form>
}