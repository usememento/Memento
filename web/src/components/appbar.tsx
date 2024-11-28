import {TapRegion} from "./button.tsx";
import {MdArrowBack} from "react-icons/md";
import {useNavigate} from "react-router";

export default function Appbar({title, hideTitle}: {title: string, hideTitle?: boolean}) {
    const navigate = useNavigate();

    return <div className={"h-12 sticky w-full flex flex-row px-2 items-center text-xl"}>
        <TapRegion onPress={() => {
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