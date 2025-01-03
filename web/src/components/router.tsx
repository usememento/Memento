import { createBrowserRouter } from "react-router";
import LoginPage from "../pages/login_page.tsx";
import RegisterPage from "../pages/register_page.tsx";
import NaviBar from "./navi.tsx";
import HomePage from "../pages/home.tsx";
import ExplorePage from "../pages/explore_page.tsx";
import FollowingPage from "../pages/following.tsx";
import SearchPage from "../pages/search_page.tsx";
import UserPage from "../pages/user_page.tsx";
import TaggedPostsPage from "../pages/tagged_post_page.tsx";
import PostPage from "../pages/post_page.tsx";
import ResourcesPage from "../pages/resources_page.tsx";
import SettingsPage from "../pages/settings_page.tsx";
import PostEditPage from "../pages/post_edit_page.tsx";

export const router = createBrowserRouter([
    {
        path: "/login",
        element: <LoginPage />,
    },
    {
        path: "/register",
        element: <RegisterPage />,
    },
    {
        element: <NaviBar />,
        children: [
            {
                path: "/",
                element: <HomePage />,
            },
            {
                path: "/explore",
                element: <ExplorePage />,
            },
            {
                path: "/following",
                element: <FollowingPage />,
            },
            {
                path: "/search",
                element: <SearchPage />,
            },
            {
                path: "/resources",
                element: <ResourcesPage />,
            },
            {
                path: "/settings",
                element: <SettingsPage />,
            },
            {
                path: "/user/:username",
                element: <UserPage />,
            },
            {
                path: "/tag/:tag",
                element: <TaggedPostsPage />,
            },
            {
                path: "/post/:id",
                element: <PostPage />,
            },
            {
                path: "/post/:id/edit",
                element: <PostEditPage/>
            }
        ]
    },
])