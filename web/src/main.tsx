import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import {NextUIProvider} from "@nextui-org/react";
import app from "./app.ts";
import Theme from "./components/theme.tsx";
import { router } from './components/router.tsx';
import {RouterProvider} from "react-router";

app.init()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <NextUIProvider>
        <Theme>
            <RouterProvider router={router}></RouterProvider>
        </Theme>
    </NextUIProvider>
  </StrictMode>,
)
