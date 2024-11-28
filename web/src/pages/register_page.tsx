import {Button, Input, Slider, Spinner} from "@nextui-org/react";
import {useContext, useState} from "react";
import app from "../app.ts";
import showMessage, {dialogCanceler, showDialog} from "../components/message.tsx";
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
            <form className={"py-4"} id={"login"} onSubmit={async (event) => {
                event.preventDefault();
                if(password !== confirmPassword) {
                    showMessage({text: translate("Passwords do not match")});
                    return;
                }
                if (isLoading) return;
                setIsLoading(true);
                const captchaRes = await fetch(`${app.server}/api/captcha/create`);
                if(!captchaRes.ok) {
                    showMessage({text: "Failed to load captcha"});
                    setIsLoading(false);
                    return;
                }
                const captcha: Captcha = await captchaRes.json();
                let value = 0
                await showDialog({
                    title: "Move the slider to correct position",
                    children: <CaptchaWidget Captcha={captcha} onFinished={(v) => {
                        value = v;
                    }}/>
                })
                const verify = await fetch(`${app.server}/api/captcha/verify`, {
                    method: "POST",
                    body: `identifier=${captcha.identifier}&answer=${value}`,
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                })
                if(!verify.ok) {
                    showMessage({text: "Failed to verify captcha"});
                    setIsLoading(false);
                    return;
                }
                const token = (await verify.json()).captcha_token;
                fetch(`${app.server}/api/user/create`, {
                    method: "POST",
                    body: `username=${username}&password=${password}&captchaToken=${token}&grant_type=password`,
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    }
                }).then(async (res) => {
                    setIsLoading(false);
                    if (res.ok) {
                        const json = await res.json();
                        app.user = json.user;
                        app.token = json.accessToken;
                        app.refreshToken = json.refreshToken;
                        app.writeData();
                        navigate('/', {replace: true});
                    } else {
                        const json = await res.json();
                        showMessage({text: json.message})
                    }
                })
            }}>
                <Input type={"text"} label={translate("Username")} variant={"bordered"} value={username}
                       onChange={(v) => setUsername(v.target.value)}></Input>
                <div className={"h-4"}></div>
                <Input type={"password"} label={translate("Password")} variant={"bordered"} value={password}
                       onChange={(v) => setPassword(v.target.value)}></Input>
                <div className={"h-4"}></div>
                <Input type={"password"} label={translate("Confirm Password")} variant={"bordered"}
                       value={confirmPassword}
                       validate={(v) => v === password ? "" : translate("Passwords do not match")}
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

interface Captcha {
    identifier: string;
    slider: string; // base64 encoded image
    bg: string; // base64 encoded image
}

function CaptchaWidget({Captcha, onFinished}: {Captcha: Captcha, onFinished: (value: number) => void}) {
    const [value, setValue] = useState(0);
    const canceler = useContext(dialogCanceler);

    return <div className={"h-56 w-full flex flex-col justify-center items-center"}>
        <div className={"relative"} style={{
            width: "256px",
            height: "160px"
        }}>
            <img src={`data:image/png;base64,${Captcha.bg}`} alt={"bg"} className={"rounded-md w-full h-full"}/>
            <div className={"absolute w-9 h-9 shadow"} style={{
                left: `${value}px`,
                top: "62px"
            }}>
                <img src={`data:image/png;base64,${Captcha.slider}`} alt={"slider"} className={"w-full h-full"}/>
            </div>
        </div>
        <div className={"mt-4"} style={{
            width: "256px",
        }}>
            <Slider value={value} minValue={0} maxValue={220} onChange={(v) => {
                setValue(v as number);
            }} onChangeEnd={() => {
                onFinished(Math.floor(value*100/220));
                canceler();
            }}></Slider>
        </div>
    </div>
}