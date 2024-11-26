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

app.init()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <NextUIProvider>
        <BrowserRouter>
            <Routes>
                <Route path={"/login"} element={<LoginPage></LoginPage>}/>
                <Route path={"/register"} element={<RegisterPage></RegisterPage>}/>
                <Route element={<NaviBar />}>
                    <Route path={"/"} element={HomePage()}/>
                </Route>
            </Routes>
        </BrowserRouter>
    </NextUIProvider>
  </StrictMode>,
)
