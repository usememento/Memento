import {useState} from "react";
import {Input} from "@nextui-org/react";
import {MdSearch} from "react-icons/md";
import {useNavigate} from "react-router";

export default function SearchBar() {
    const [text, setText] = useState("");

    const navigate = useNavigate();

    return <div className={"w-full h-10 px-4 py-2"}>
        <form onSubmit={(event) => {
            event.preventDefault();
            navigate(`/search?keyword=${text}`);
        }}>
            <Input startContent={<MdSearch size={24}/>} value={text}
                   onChange={event => setText(event.target.value)}></Input>
        </form>
    </div>
}