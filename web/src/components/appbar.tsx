import {TapRegion} from "./button.tsx";
import {MdArrowBack} from "react-icons/md";
import {useNavigate} from "react-router";

export default function Appbar({title, hideTitle, onBack}: {title: string, hideTitle?: boolean, onBack?: () => void}) {
    const navigate = useNavigate();

    return <div className={"h-12 sticky w-full flex flex-row px-2 items-center text-xl top-0 bg-background z-50"}>
        <TapRegion onPress={() => {
            if (onBack) {
                onBack();
                return;
            }
            console.log(window.history.length);
            if (window.history.length === 1) {
                navigate("/", {replace: true});
                return;
            }
            navigate(-1);
        }} borderRadius={9999}>
            <div
                className={`w-10 h-10 flex flex-row items-center justify-center text-2xl`}>
                <MdArrowBack/>
            </div>
        </TapRegion>
        <span className={"w-2"} />
        <span className={`flex-grow ${hideTitle ? "opacity-0" : "opacity-100"} duration-200 transition-opacity`}>
            {title}
        </span>
    </div>
}