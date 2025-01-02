import React, {useCallback, useContext, useEffect, useState} from "react";
import {MdOutlineCloudUpload, MdOutlineCopyAll, MdOutlineDescription} from "react-icons/md";
import {Tr} from "../components/translate.tsx";
import MultiPageList from "../components/multi_page_list.tsx";
import {network} from "../network/network.ts";
import {Resource} from "../network/model.ts";
import {IconButton, TapRegion} from "../components/button.tsx";
import {Button, Progress} from "@nextui-org/react";
import showMessage, {dialogCanceler, showDialog} from "../components/message.tsx";
import app from "../app.ts";

export default function ResourcesPage() {
    const [listKey, setListKey] = useState(0);

    const handleUpload = useCallback((file: File) => {
        console.log("uploading file", file);
        showDialog({
            children: <UploadingDialog file={file} onUpload={() => {
                showMessage({
                    text: "Upload success",
                });
                setListKey(prev => prev+1);
            }}></UploadingDialog>,
            title: "Uploading",
        })
    }, []);

    const onDelete = useCallback(() => {
        setListKey(prev => prev+1);
    }, []);

    return <div className={"px-4 pt-4 overflow-y-auto w-full h-full"}>
        <UploadWidget onUpload={handleUpload}></UploadWidget>
        <div className={"h-4"}/>
        <ResourcesList key={listKey} onDelete={onDelete}></ResourcesList>
    </div>
}

function UploadWidget({onUpload}: {onUpload: (file: File) => void}) {
    const selectFile = useCallback(() => {
        console.log("select file");
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = '*/*';
        input.onchange = async () => {
            const file = input.files?.[0];
            if (!file) return;
            onUpload(file);
        };
        input.click();
    }, [onUpload]);

    const handleDrop = useCallback((e: React.DragEvent) => {
        console.log("drop");
        e.preventDefault();
        e.stopPropagation();
        const file = e.dataTransfer.files?.[0];
        if (!file) return;
        onUpload(file);
    }, [onUpload]);

    const handleDragOver = useCallback((e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
    }, []);
    
    return <div
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onClick={selectFile}
        className={"w-full h-28 border rounded-2xl bg-content2 flex items-center justify-center cursor-pointer"}>
        <div>
            <div className={"h-10 flex items-center justify-center"}>
                <MdOutlineCloudUpload size={32}/>
            </div>
            <p className={"font-bold text-xl"}><Tr>Select a file</Tr></p>
            <div className={"h-6 flex items-center justify-center"}>
                <p className={"text-accent-foreground text-sm"}><Tr>Or drag it here</Tr></p>
            </div>
        </div>
    </div>
}

function ResourcesList({onDelete}: {onDelete: () => void}) {
    const builder = useCallback((item: Resource) => {
        return <ResourceWidget key={item.id} resource={item} onDelete={onDelete}></ResourceWidget>
    }, [onDelete])

    return <MultiPageList itemBuilder={builder} loader={network.getResources}></MultiPageList>
}

function ResourceWidget({resource, onDelete}: {resource: Resource, onDelete: () => void}) {
    return <TapRegion onPress={() => {
        showDialog({
            children: <ItemInfoDialog resource={resource} onDelete={onDelete}></ItemInfoDialog>,
            title: resource.filename,
        });
    }}>
        <div className={"h-12 w-full flex flex-row items-center px-4"}>
            <MdOutlineDescription size={24}/>
            <span className={"w-2"}/>
            <span>{resource.filename}</span>
            <span className={"flex-grow"}/>
            <span>{formatTime(resource.time)}</span>
        </div>
    </TapRegion>
}

function formatTime(time: string) {
    const date = new Date(time);
    return date.toLocaleString();
}

function UploadingDialog({file, onUpload}: {file: File, onUpload: () => void}) {
    const [progress, setProgress] = useState(0);
    
    const canceler = useContext(dialogCanceler)

    useEffect(() => {
        network.uploadFile(file, (progress) => {
            setProgress(progress);
        }).then(() => {
            onUpload();
            canceler();
        }).catch(() => {
            showMessage({
                text: "Upload failed",
            });
            canceler();
        });
    }, [canceler, file, onUpload]);

    return <div className={"py-4 px-2"}>
        <div className={"h-8"}></div>
        <Progress value={progress * 100}/>
    </div>
}

function ItemInfoDialog({resource, onDelete}: {resource: Resource, onDelete: () => void}) {
    const [isDeleting, setIsDeleting] = useState(false);

    const canceler = useContext(dialogCanceler);

    return <div className={"p-2"}>
        <div className={"border rounded flex flex-row items-center py-1"}>
            <span className={"flex-grow overflow-auto px-2"}>{`https://${app.server}/api/file/download/${resource.id}`}</span>
            <IconButton onPress={() => {
                navigator.clipboard.writeText(`https://${app.server}/api/file/download/${resource.id}`);
                showMessage({
                    text: "Copied",
                })
            }}>
                <MdOutlineCopyAll/>
            </IconButton>
        </div>
        <div className={"flex flex-row-reverse"}>
            <Button className={"mt-2 h-8"} color={"danger"} onClick={() => {
                if (isDeleting) return;
                setIsDeleting(true);
                network.deleteFile(resource.id.toString()).then(() => {
                    setIsDeleting(false);
                    showMessage({
                        text: "Delete success",
                    });
                    canceler();
                    onDelete();
                }).catch(() => {
                    setIsDeleting(false);
                    showMessage({
                        text: "Delete failed",
                    });
                });
            }}><Tr>Delete</Tr></Button>
        </div>
    </div>
}