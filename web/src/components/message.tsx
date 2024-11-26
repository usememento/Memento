import {ReactNode} from "react";

export default function showMessage({icon, text}:{ icon?: ReactNode, text: string }) {
    const div = document.createElement("div");
    div.className = "fixed left-0 right-0 bottom-4 flex items-center justify-center";
    div.innerHTML = `
        <div class="w-full h-12 bg-default-800 text-white p-4 rounded-md shadow-lg max-w-sm flex items-center justify-center animate-appearance-in">
            ${icon ? `<div class="mr-4">${icon}</div>` : ""}
            <div class="flex-grow">${text}</div>
        </div>
    `;
    document.body.appendChild(div);
    setTimeout(() => {
        div.remove();
    }, 3000);
}