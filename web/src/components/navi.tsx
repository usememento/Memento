import {ReactNode, useEffect, useState} from "react";
import {
    MdOutlineExitToApp,
    MdOutlineExplore,
    MdOutlineHome,
    MdOutlineLibraryBooks, MdOutlinePerson, MdOutlineSettings,
    MdOutlineSubscriptions
} from "react-icons/md";
import app from "../app.ts";
import {TapRegion} from "./button.tsx";
import {
    Avatar,
    Dropdown, DropdownItem,
    DropdownMenu,
    DropdownTrigger,
} from "@nextui-org/react";
import {useLocation, useNavigate, useOutlet} from "react-router";
import {Tr, translate} from "./translate.tsx";
import {getAvatar} from "../network/model.ts";
import {AnimatePresence, motion} from "framer-motion";

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

export default function NaviBar() {
    const [naviType, setNaviType] = useState(getNaviType());

    const [isOpen, setIsOpen] = useState(false)

    useEffect(() => {
        const updater = () => {
            setNaviType(getNaviType());
        };
        window.addEventListener("resize", updater);
        return () => {
            window.removeEventListener("resize", updater);
        };
    }, []);

    const location = useLocation()
    function getPageName() {
        switch (window.location.pathname) {
            case '/':
                return 'Home'
            case '/explore':
                return 'Explore'
            case '/following':
                return 'Following'
            case '/resources':
                return 'Resources'
            case '/settings':
                return 'Settings'
            default:
                return ''
        }
    }
    const [pageName, setPageName] = useState(getPageName())

    useEffect(() => {
        setPageName(getPageName())
    }, [location]);

    if (naviType === NaviType.top) {
        return <div className={"w-full h-full no-select"}>
            <div
                className={`z-20 fixed left-0 right-0 top-0 bottom-0 bg-black bg-opacity-20 ${isOpen ? "" : "hidden"} animate-appearance-in`}
                onClick={() => {
                    setIsOpen(false)
                }}/>
            <div className={"fixed top-0 bottom-0 w-64 z-50 bg-background duration-200 px-2"} style={{
                left: isOpen ? "0" : "-256px",
            }}>
                <UserPart></UserPart>
                <NaviList link={window.location.pathname}/>
            </div>
            <div className={"h-14 w-full fixed flex flex-row top-0 left-0 right-0 items-center px-4 border-b"}>
                <TapRegion onPress={() => {
                    setIsOpen(!isOpen)
                }} borderRadius={24}>
                    <Avatar src={getAvatar(app.user)} className={"m-1"} size={"md"}></Avatar>
                </TapRegion>
                <div className={"flex-grow text-lg pl-4"}><Tr>{pageName}</Tr></div>
            </div>
            <div className={"w-full h-full pt-14"}>
                <AnimatedOutlet></AnimatedOutlet>
            </div>
        </div>
    } else {
        return <div className={"w-full h-full flex flex-row no-select max-w-screen-xl m-auto"}>
            <div className={"h-full w-64 px-4 border-r"}>
                <UserPart></UserPart>
                <NaviList link={window.location.pathname}/>
            </div>
            <div className={"flex-grow"}>
                <AnimatedOutlet></AnimatedOutlet>
            </div>
        </div>
    }
}

const AnimatedOutlet = () => {
    const location = useLocation(); // provided by react-router-dom
    const element = useOutlet(); // provided by react-router-dom

    return (
        <AnimatePresence key={location.pathname}>
            {element && (
                <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className='container'
                >
                    {element}
                </motion.div>
            )}
        </AnimatePresence>
    );
};

function NaviItem({icon, text, link, current}: { icon: ReactNode, text: string, link: string, current: string }) {
    const navigate = useNavigate()

    const isActivated = current === link

    return <TapRegion borderRadius={16} onPress={() => {
        navigate(link)
    }}>
        <div className={`w-full h-12 flex flex-row text-lg  justify-center items-center px-4 duration-200
          ${isActivated ? "text-primary-500 font-bold" : "text-default-900"}`}>
            {icon}
            <span className={"w-3"}></span>
            <div className={"flex-grow pt-0.5"}>
                <Tr>{text}</Tr>
            </div>
        </div>
    </TapRegion>
}

function NaviList({link}: { link: string }) {
    return <>
        <NaviItem icon={<MdOutlineHome size={24}/>} text={"Home"} link={"/"} current={link}></NaviItem>
        <NaviItem icon={<MdOutlineExplore size={24}/>} text={"Explore"} link={"/explore"} current={link}></NaviItem>
        <NaviItem icon={<MdOutlineSubscriptions size={24}/>} text={"Following"} link={"/following"}
                  current={link}></NaviItem>
        <NaviItem icon={<MdOutlineLibraryBooks size={24}/>} text={"Resources"} link={"/resources"}
                  current={link}></NaviItem>
        <NaviItem icon={<MdOutlineSettings size={24}/>} text={"Settings"} link={"/settings"} current={link}></NaviItem>
    </>
}

function UserPart() {
    const user = app.user
    const navigate = useNavigate()

    const [isOpen, setIsOpen] = useState(false)

    return <div className={"py-4"}>
        <Dropdown className={"px-2 py-2"} isOpen={isOpen} onOpenChange={(b) => {
            if (b) {
                if (!user) {
                    navigate("/login")
                } else {
                    setIsOpen(!isOpen)
                }
            } else {
                setIsOpen(false)
            }
        }}>
            <DropdownTrigger>
                <button className={"w-full text-start hover:bg-content2 active:bg-content3 duration-200 rounded-2xl"}>
                    <div className={"w-full h-14 flex flex-row justify-center items-center px-4"}>
                        <Avatar src={getAvatar(app.user)}></Avatar>
                        <div className={"flex-grow pl-3"}>{user?.username ?? translate("Login")}</div>
                    </div>
                </button>
            </DropdownTrigger>
            <DropdownMenu className={"py-2"} onAction={(key) => {
                if (key === "me") {
                    navigate(`/user/${app.user?.username}`)
                } else if (key === "exit") {
                    app.clearData();
                    navigate("/login")
                }
            }}>
                <DropdownItem key={"me"} className={"py-2 min-w-48 px-3"}
                              startContent={<MdOutlinePerson size={18}/>}><Tr>My Profile</Tr></DropdownItem>
                <DropdownItem key={"exit"} color={"danger"} className={"py-2 min-w-48 px-3"}
                              startContent={<MdOutlineExitToApp size={18}/>}><Tr>Log out</Tr></DropdownItem>
            </DropdownMenu>
        </Dropdown>
    </div>
}
