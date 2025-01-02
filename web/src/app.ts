import {User} from "./network/model.ts";


class _App {
    user: User | null = null;

    token: string | null = null;

    refreshToken: string | null = null;

    get server() {
        // return "http://localhost:1323";
        return "https://note.nyne.dev";
    }

    _locale = "system"

    defaultPostVisibility = "public";

    version = "1.0.0";

    get locale() {
        let locale = this._locale;
        if (locale === "system") {
            locale = navigator.language;
        }
        if(locale.startsWith("en")) {
            return "en-US";
        }
        if (![ "zh-CN", "zh-TW", "en-US" ].includes(locale)) {
            return "en-US";
        }
        return locale;
    }

    init() {
        const data = localStorage.getItem("data");
        if (data) {
            const json = JSON.parse(data);
            this.user = json.user;
            this.token = json.token;
            this.refreshToken = json.refreshToken;
            this._locale = json._locale ?? "system";
            this.defaultPostVisibility = json.defaultPostVisibility ?? "public";
        }
    }

    writeData() {
        const data = {
            user: this.user,
            token: this.token,
            refreshToken: this.refreshToken,
            locale: this._locale,
            defaultPostVisibility: this.defaultPostVisibility,
        }
        localStorage.setItem("data", JSON.stringify(data));
    }

    clearData() {
        localStorage.removeItem("data");
        this.user = null;
        this.token = null;
        this.refreshToken = null;
    }
}

const app = new _App();

export default app;