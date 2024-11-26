import {Button, Input, Spinner} from "@nextui-org/react";
import {useState} from "react";
import app from "../app.ts";
import {User} from "../network/model.ts";
import showMessage from "../components/message.tsx";
import {useNavigate} from "react-router";
import {Tr, translate} from "../components/translate.tsx";

export default function RegisterPage() {
    const [isLoading, setIsLoading] = useState(false);
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [confirmPassword, setConfirmPassword] = useState("");
    const navigate = useNavigate();

    return <div className={"w-full h-full bg-content2 flex items-center justify-center"}>
        <div className={"w-full max-w-sm bg-content1 mx-4 p-6 rounded-xl shadow-lg"}>
            <p className={"font-bold text-2xl"}><Tr>Register</Tr></p>
            <div className={"h-4"}></div>
            <form className={"py-4"} id={"login"} onSubmit={(event) => {
                event.preventDefault();
                if (isLoading) return;
                setIsLoading(true);
                fetch(`${app.server}/api/user/create`, {
                    method: "POST",
                    body: `username=${username}&password=${password}`,
                }).then(async (res) => {
                    setIsLoading(false);
                    if (res.ok) {
                        const json = await res.json();
                        app.user = new User(json.user)
                        app.token = json.token.access_token;
                        app.refreshToken = json.token.refresh_token;
                        app.writeData();
                    } else {
                        showMessage({text: "Login failed"})
                    }
                })
            }}>
                <Input type={"text"} label={translate("Username")} variant={"bordered"} value={username}
                       onChange={(v) => setUsername(v.target.value)}></Input>
                <div className={"h-4"}></div>
                <Input type={"password"} label={translate("Password")} variant={"bordered"} value={password}
                       onChange={(v) => setPassword(v.target.value)}></Input>
                <div className={"h-4"}></div>
                <Input type={"password"} label={translate("Confirm Password")} variant={"bordered"} value={confirmPassword}
                       onChange={(v) => setConfirmPassword(v.target.value)}></Input>
                <div className={"h-6"}></div>
                <div className={"flex w-full"}>
                    <Button disabled={isLoading} type={"submit"} color={"primary"} fullWidth={true}>
                        {isLoading ? <Spinner color={"default"} size={"sm"}></Spinner> : translate("Continue")}
                    </Button>
                </div>
                <div className={"h-2"}></div>
                <div className={"flex w-full justify-center"}>
                    <Button variant={"light"} color={"primary"} onClick={() => {
                        navigate("/login");
                    }}>
                        <Tr>Already have an account? Login</Tr>
                    </Button>
                </div>
            </form>
        </div>
    </div>
}