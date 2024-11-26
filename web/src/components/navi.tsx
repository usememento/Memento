import {ReactNode, useEffect, useState} from "react";
import {
    MdOutlineExplore,
    MdOutlineHome,
    MdOutlineLibraryBooks, MdOutlineSettings,
    MdOutlineSubscriptions
} from "react-icons/md";
import app from "../app.ts";
import {TapRegion} from "./button.tsx";
import {Avatar} from "@nextui-org/react";
import {useNavigate} from "react-router";
import {translate} from "./translate.tsx";

enum NaviType {
    top,
    left,
}

function getNaviType() {
    if (window.innerWidth < 600) {
        return NaviType.top;
    } else {
        return NaviType.left;
    }
}

export default function NaviBar({children}: {children?: ReactNode}) {

    const [naviType, setNaviType] = useState(getNaviType());

    useEffect(() => {
        window.addEventListener("resize", () => {
            setNaviType(getNaviType());
        });
    }, []);

    if(naviType === NaviType.top) {
        return <div className={"w-full h-full"}>
            <div className={"h-14 w-full fixed"}>

            </div>
            {children}
        </div>
    } else {
        return <div className={"w-full h-full flex flex-row no-select max-w-screen-xl m-auto"}>
            <div className={"h-full w-64 px-4 border-r"}>
                <UserPart></UserPart>
                <NaviList/>
            </div>
            <div className={"flex-grow"}>
                {children}
            </div>
        </div>
    }
}

function NaviItem({icon, text, link}: {icon: ReactNode, text: string, link: string}) {
    const [isActivated, setIsActivated] = useState(window.location.pathname === link);

    useEffect(() => {
        window.addEventListener("popstate", () => {
            setIsActivated(window.location.pathname === link);
        });
    }, [link]);

    return <div className={`w-full h-12 flex flex-row text-lg  justify-center items-center px-4 duration-200
          ${isActivated ? "text-primary-500 font-bold" : "text-default-900 cursor-pointer hover:text-opacity-80 active:text-opacity-60"}`}>
        {icon}
        <span className={"w-3"}></span>
        <div className={"flex-grow pt-0.5"}>
            {text}
        </div>
    </div>
}

function NaviList() {
    return <>
        <NaviItem icon={<MdOutlineHome size={24}/>} text={"Home"} link={"/"}></NaviItem>
        <NaviItem icon={<MdOutlineExplore size={24}/>} text={"Explore"} link={"/explore"}></NaviItem>
        <NaviItem icon={<MdOutlineSubscriptions size={24}/>} text={"Following"} link={"/following"}></NaviItem>
        <NaviItem icon={<MdOutlineLibraryBooks size={24}/>} text={"Resource"} link={"/resources"}></NaviItem>
        <NaviItem icon={<MdOutlineSettings  size={24}/>} text={"Settings"} link={"/settings"}></NaviItem>
    </>
}

function UserPart() {
    const user = app.user
    const navigate = useNavigate()

    let avatar = user?.avatar
    if(avatar && avatar !== "user.png") {
        avatar = `${app.server}/api/user/avatar/${avatar}`
    } else {
        avatar = '/user.png'
    }

    return <div className={"py-4"}>
        <TapRegion borderRadius={8} onPress={() => {
            if(!user) {
                navigate("/login")
            }
        }}>
            <div className={"w-full h-14 flex flex-row justify-center items-center px-4"}>
                <Avatar src={avatar}></Avatar>
                <div className={"flex-grow pl-3"}>{user?.username ?? translate("Login")}</div>
            </div>
        </TapRegion>
    </div>
}