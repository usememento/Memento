import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import {BrowserRouter, Route, Routes} from "react-router";
import HomePage from "./pages/home.tsx";
import NaviBar from "./components/navi.tsx";
import {NextUIProvider} from "@nextui-org/react";
import app from "./app.ts";
import LoginPage from "./pages/login_page.tsx";
import RegisterPage from "./pages/register_page.tsx";
import Theme from "./components/theme.tsx";
import ExplorePage from "./pages/explore_page.tsx";
import FollowingPage from "./pages/following.tsx";

app.init()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <NextUIProvider>
        <Theme>
            <BrowserRouter>
                <Routes>
                    <Route path={"/login"} element={<LoginPage></LoginPage>}/>
                    <Route path={"/register"} element={<RegisterPage></RegisterPage>}/>
                    <Route element={<NaviBar />}>
                        <Route path={"/"} element={<HomePage/>}/>
                        <Route path={"/explore"} element={<ExplorePage/>}/>
                        <Route path={"/following"} element={<FollowingPage/>}/>
                    </Route>
                </Routes>
            </BrowserRouter>
        </Theme>
    </NextUIProvider>
  </StrictMode>,
)
