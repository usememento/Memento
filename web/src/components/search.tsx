import {useState} from "react";
import {Input} from "@nextui-org/react";
import {MdSearch} from "react-icons/md";
import {router} from "./router.tsx";

export default function SearchBar() {
    const [text, setText] = useState("");

    return <div className={"w-full h-10 px-4 py-2"}>
        <form onSubmit={(event) => {
            event.preventDefault();
            router.navigate(`/search?keyword=${text}`);
        }}>
            <Input startContent={<MdSearch size={24}/>} value={text}
                   onChange={event => setText(event.target.value)}></Input>
        </form>
    </div>
}