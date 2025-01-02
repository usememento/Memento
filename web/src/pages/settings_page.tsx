import {Avatar, Button, Input, Select, SelectItem, Tab, Tabs} from "@nextui-org/react";
import {TapRegion} from "../components/button.tsx";
import {ReactNode, useCallback, useContext, useEffect, useState} from "react";
import {Tr, translate} from "../components/translate.tsx";
import {
    MdArrowRight,
    MdLanguage, MdOutlineAppRegistration,
    MdOutlineBadge,
    MdOutlineDescription, MdOutlineDomain, MdOutlineImage, MdOutlineLock,
    MdOutlinePassword,
    MdOutlinePerson
} from "react-icons/md";
import {getAvatar, ServerConfig, User} from "../network/model.ts";
import app from "../app.ts";
import showMessage, {
    dialogCanceler,
    Loading,
    showDialog,
    showInputDialog,
    showLoadingDialog
} from "../components/message.tsx";
import {network} from "../network/network.ts";
import MultiPageList from "../components/multi_page_list.tsx";

export default function SettingsPage() {
    const pageNames = [
        "Account",
        "Preferences",
        "Admin",
        "About",
    ]

    const pages = [
        <Account/>,
        <Preferences/>,
        <Admin/>,
        <About/>,
    ]

    return <>
        <Tabs aria-label={"Options"} variant={"underlined"} color={"primary"} className={"w-full"} classNames={{
            tabList: "gap-6 w-full relative rounded-none border-b border-divider px-4 py-0",
            tab: "max-w-fit h-12 px-4",
            panel: "p-0 w-full"
        }}>
            {pageNames.map((name, index) => {
                return <Tab key={index} title={translate(name)}>
                    {pages[index]}
                </Tab>;
            })}
        </Tabs>
    </>
}

function ListTile({title, leading, trailing, onClick}: {
    title: string,
    leading?: ReactNode,
    trailing?: ReactNode,
    onClick?: () => void
}) {
    const body = <div className={"flex flex-row w-full h-12 px-4 items-center"}>
        {leading}
        {leading && <div className={"w-3"}/>}
        <div className={"flex-grow flex flex-row items-center"}>
            <p className={"text-lg"}>{title}</p>
        </div>
        {trailing && <div className={"w-3"}/>}
        {trailing}
    </div>

    if (onClick == null) {
        return body;
    }

    return <TapRegion onPress={onClick}>
        {body}
    </TapRegion>;
}

function Account() {
    const [accountKey, setAccountKey] = useState(0);

    if (app.user == null) {
        return <div></div>
    }

    return <div className={"w-full"} key={accountKey}>
        <ListTile onClick={() => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = 'image/*';
            input.onchange = async () => {
                const file = input.files?.[0];
                if (!file) return;
                if (file.size > 1024 * 1024 * 2) {
                    showMessage({
                        text: translate("File too large"),
                    })
                    return;
                }
                const canceler = showLoadingDialog();
                try {
                    await network.editInfo(null, null, file);
                    setAccountKey(accountKey + 1);
                } catch (e: any) {
                    showMessage({
                        text: e.toString(),
                    })
                } finally {
                    canceler();
                }
            };
            input.click();
        }} title={translate("Avatar")} leading={<MdOutlinePerson size={24}/>}
                  trailing={<Avatar src={getAvatar(app.user)} size={"sm"}/>}/>
        <ListTile title={translate("Username")} leading={<MdOutlineBadge size={24}/>}
                  trailing={<p>{app.user!.nickname}</p>} onClick={() => {
            showInputDialog("Change nickname", "Nickname", async (value) => {
                const canceler = showLoadingDialog();
                try {
                    await network.editInfo(value, null, null);
                    setAccountKey(accountKey + 1);
                } catch (e: any) {
                    showMessage({
                        text: e.toString(),
                    })
                } finally {
                    canceler();
                }
            });
        }}/>
        <ListTile trailing={<MdArrowRight/>} title={translate("Bio")} leading={<MdOutlineDescription size={24}/>}
                  onClick={() => {
                      showInputDialog("Change bio", "Bio", async (value) => {
                          const canceler = showLoadingDialog();
                          try {
                              await network.editInfo(null, value, null);
                              setAccountKey(accountKey + 1);
                          } catch (e: any) {
                              showMessage({
                                  text: e.toString(),
                              })
                          } finally {
                              canceler();
                          }
                      });
                  }}/>
        <ListTile trailing={<MdArrowRight/>} title={translate("Password")} leading={<MdOutlinePassword size={24}/>}
                  onClick={() => {
                      showDialog({
                          children: <PasswordDialog/>,
                          title: translate("Change password"),
                      })
                  }}/>
    </div>
}

function Preferences() {
    const [state, setState] = useState({
        locale: app._locale,
        defaultPostVisibility: app.defaultPostVisibility,
    });
    return <div className={"w-full"}>
        <ListTile
            title={translate("Language")}
            leading={<MdLanguage size={24}/>}
            trailing={<Select size={"sm"} selectionMode={"single"} className={"max-w-32"} selectedKeys={[state.locale]}
                              onChange={(e) => {
                                  if (e.target.value) {
                                      app._locale = e.target.value;
                                      setState(prev => ({...prev, locale: e.target.value}));
                                  }
                              }}>
                <SelectItem key={"system"} value={"system"}>System</SelectItem>
                <SelectItem key={"en-US"} value={"en-US"}>English</SelectItem>
                <SelectItem key={"zh-CN"} value={"zh-CN"}>简体中文</SelectItem>
                <SelectItem key={"zh-TW"} value={"zh-TW"}>繁体中文</SelectItem>
            </Select>}
        />
        <ListTile
            title={translate("Default Post Visibility")}
            leading={<MdOutlineLock size={24}/>}
            trailing={<Select size={"sm"} selectionMode={"single"} className={"max-w-32"}
                              selectedKeys={[state.defaultPostVisibility]} onChange={(e) => {
                if (e.target.value) {
                    app.defaultPostVisibility = e.target.value;
                    setState(prev => ({...prev, defaultPostVisibility: e.target.value}));
                }
            }}>
                <SelectItem key={"public"} value={"public"}>{translate("Public")}</SelectItem>
                <SelectItem key={"private"} value={"private"}>{translate("Private")}</SelectItem>
            </Select>}
        />
    </div>
}

function Admin() {
    const [config, setConfig] = useState<ServerConfig | null>(null);

    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        network.getServerConfig().then(setConfig);
    }, []);

    if (app.user?.isAdmin !== true) {
        return <div></div>
    }

    if (config == null) {
        return <div className={"w-full h-24 flex items-center justify-center"}>
            <Loading></Loading>
        </div>
    }

    return <div className={"w-full"}>
        <ListTile title={"Site Name"} leading={<MdOutlineDomain size={24}/>} trailing={<p>{config.siteName}</p>}
                  onClick={() => {
                      showInputDialog("Site Name", "name", async (value) => {
                          await network.setServerConfig({...config, siteName: value});
                          setConfig({...config, siteName: value});
                      });
                  }}/>
        <ListTile title={"Enable Register"} leading={<MdOutlineAppRegistration size={24}/>}
                  trailing={<Select isLoading={isLoading} size={"sm"} selectionMode={"single"} className={"max-w-32"}
                                    selectedKeys={[config.enableRegister ? "1" : "0"]} onChange={(e) => {
                      if (e.target.value) {
                          setIsLoading(true);
                          network.setServerConfig({...config, enableRegister: e.target.value === "1"}).then(() => {
                              setIsLoading(false);
                              setConfig({...config, enableRegister: e.target.value === "1"});
                          }).catch((e) => {
                              showMessage({
                                  text: e.toString(),
                              });
                              setIsLoading(false);
                          });
                      }
                  }}>
                      <SelectItem key={"0"} value={"1"}>{translate("Enabled")}</SelectItem>
                      <SelectItem key={"1"} value={"0"}>{translate("Disabled")}</SelectItem>
                  </Select>}/>
        <ListTile title={"Site Description"} leading={<MdOutlineDescription size={24}/>}
                  trailing={<MdArrowRight size={"24"}/>} onClick={() => {
            showInputDialog("Site Description", "description", async (value) => {
                await network.setServerConfig({...config, description: value});
                setConfig({...config, description: value});
            }, config?.description);
        }}/>
        <ListTile title={"Site Icon"} leading={<MdOutlineImage size={24}/>} trailing={<MdArrowRight size={"24"}/>}
                  onClick={() => {
                      const input = document.createElement('input');
                      input.type = 'file';
                      input.accept = 'image/*';
                      input.onchange = async () => {
                          const file = input.files?.[0];
                          if (!file) return;
                          if (file.size > 1024 * 1024 * 4) {
                              showMessage({
                                  text: translate("File too large"),
                              })
                              return;
                          }
                          const canceler = showLoadingDialog();
                          try {
                              await network.setSiteIcon(file);
                              showMessage({
                                  text: translate("Icon changed"),
                              })
                          } catch (e: any) {
                              showMessage({
                                  text: e.toString(),
                              })
                          } finally {
                              canceler();
                          }
                      };
                      input.click();
                  }}/>
        <UserList/>
    </div>
}

function About() {
    return <div className={"w-full"}>
        <p className={"text-2xl py-4 px-4"}>Memento</p>
        <div className={"w-full py-2 px-4"}>
            <p>Version</p>
            <p className={"text-sm"}>{app.version}</p>
        </div>
        <TapRegion onPress={() => {
            window.open("https://github.com/useMemento/Memento");
        }}>
            <div className={"w-full py-2 px-4"}>
                <p>Github</p>
                <p className={"text-sm"}>https://github.com/useMemento/Memento</p>
            </div>
        </TapRegion>
    </div>
}

function PasswordDialog() {
    const [state, setState] = useState({
        oldPassword: "",
        newPassword: "",
        confirmPassword: "",
    });

    const canceler = useContext(dialogCanceler);

    return <form onSubmit={async (e) => {
        console.log(state);
        e.preventDefault();
        if (state.newPassword !== state.confirmPassword) {
            showMessage({
                text: translate("Passwords do not match"),
            });
            return;
        }
        const loadingCanceler = showLoadingDialog();
        try {
            await network.changePassword(state.oldPassword, state.newPassword);
            showMessage({
                text: translate("Password changed"),
            });
            canceler();
        } catch (e: any) {
            showMessage({
                text: e.toString(),
            });
        } finally {
            loadingCanceler();
        }
    }}>
        <div className={"h-2"}></div>
        <Input type={"password"} placeholder={translate("Old Password")} value={state.oldPassword}
               onChange={(v) => setState(prev => ({...prev, oldPassword: v.target.value}))}></Input>
        <div className={"h-2"}></div>
        <Input type={"password"} placeholder={translate("New Password")} value={state.newPassword}
               onChange={(v) => setState(prev => ({...prev, newPassword: v.target.value}))}></Input>
        <div className={"h-2"}></div>
        <Input type={"password"} placeholder={translate("Confirm Password")}
               value={state.confirmPassword}
               validate={(v) => v === state.newPassword ? "" : translate("Passwords do not match")}
               onChange={(v) => setState(prev => ({...prev, confirmPassword: v.target.value}))}></Input>
        <div className={"h-4"}></div>
        <div>
            <Button type={"submit"} color={"primary"} className={"w-full"}><Tr>Confirm</Tr></Button>
        </div>
        <div className={"h-2"}></div>
    </form>
}

function UserListTile({user, onDelete}: { user: User, onDelete: () => void }) {

    return <TapRegion onPress={() => {
        showDialog({
            title: user.nickname == "" ? " " : user.nickname,
            children: <UserDetailDialog user={user} onDelete={onDelete}/>,
        })
    }}>
        <div className={"w-full h-12 flex items-center px-4"}>
            <Avatar src={getAvatar(user)} size={"sm"}></Avatar>
            <span className={"w-3"}></span>
            <span>{user.nickname}</span>
            <span className={"flex-grow"}></span>
            <MdArrowRight size={24}></MdArrowRight>
        </div>
    </TapRegion>
}

function UserList() {
    const [key, setKey] = useState(0);

    const reload = useCallback(() => {
        setKey(prev => prev+1);
    }, []);

    return <>
        <p className={"px-4 my-2 text-lg font-bold"}>Users</p>
        <MultiPageList key={key} itemBuilder={(u) => <UserListTile key={u.username} user={u} onDelete={reload}/>} loader={network.listUsers}></MultiPageList>
    </>
}

function UserDetailDialog({user, onDelete}: { user: User, onDelete: () => void }) {
    const [isDeleting, setIsDeleting] = useState(false);
    const [isAdmin, setIsAdmin] = useState(user.isAdmin);
    const [isSettingAdmin, setIsSettingAdmin] = useState(false);

    const canceler = useContext(dialogCanceler);

    return <div>
        <ListTile title={"Register At"} trailing={<span>{formatTime(user.registeredAt)}</span>}></ListTile>
        <ListTile title={"Total Posts"} trailing={<span>{user.totalPosts}</span>}></ListTile>
        <div className={"flex flex-row-reverse"}>
            <Button isLoading={isDeleting} color={"danger"} className={"h-9"} onClick={() => {
                setIsDeleting(true);
                network.deleteUser(user.username).then(() => {
                    setIsDeleting(false);
                    canceler();
                    onDelete();
                }).catch((e) => {
                    setIsDeleting(false);
                    showMessage({
                        text: e.toString(),
                    });
                });
            }}><Tr>Delete</Tr></Button>
            <span className={"w-2"}></span>
            <Button isLoading={isSettingAdmin} variant={"bordered"} className={"h-9"} onClick={() => {
                setIsSettingAdmin(true);
                network.setPermission(user.username, !isAdmin).then(() => {
                    setIsAdmin(!isAdmin);
                    setIsSettingAdmin(false);
                    user.isAdmin = !isAdmin;
                }).catch((e) => {
                    setIsSettingAdmin(false);
                    showMessage({
                        text: e.toString(),
                    });
                });
            }}><Tr>{isAdmin ? "Set as user" : "Set as admin"}</Tr></Button>
        </div>
    </div>
}

function formatTime(time: string) {
    return new Date(time).toLocaleString();
}