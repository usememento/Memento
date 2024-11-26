import {User} from "./network/model.ts";


class _App {
    user: User | null = null;

    token: string | null = null;

    refreshToken: string | null = null;

    // Only for development, replace to empty string for production
    server = "https://note.nyne.dev"

    locale = "en"

    init() {
        const data = localStorage.getItem("data");
        if (data) {
            const json = JSON.parse(data);
            this.user = new User(json.user);
            this.token = json.token;
            this.refreshToken = json.refreshToken;
        }
        this.locale = navigator.language;
    }

    writeData() {
        const data = {
            user: this.user?.toJson(),
            token: this.token,
            refreshToken: this.refreshToken,
        }
        localStorage.setItem("data", JSON.stringify(data));
    }
}

const app = new _App();

export default app;