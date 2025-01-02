import React, {useCallback, useEffect, useRef, useState} from "react";
import {Tr, translate} from "./translate.tsx";
import {IconButton, TapRegion} from "./button.tsx";
import {MdLock, MdOutlineImage, MdOutlineInfo, MdPublic} from "react-icons/md";
import {Button} from "@nextui-org/react";
import {network} from "../network/network.ts";
import showMessage, {Loading, showLoadingDialog} from "./message.tsx";
import app from "../app.ts";

export interface EditorData {
  text: string;
  isPublic: boolean;
  isUploading: boolean;
  isUploadingImage: boolean;
}

interface EditorProps {
  initialText?: string;
  isPublic?: boolean;
  fullHeight?: boolean;
  onChanged: (data: EditorData) => void;
  submit: () => Promise<void>;
}

export default function Editor({initialText, isPublic, fullHeight, onChanged, submit}: EditorProps) {
  const [state, setState] = useState<EditorData>({
    text: (initialText ?? "").replace("\r\n", "\n"),
    isPublic: isPublic ?? true,
    isUploading: false,
    isUploadingImage: false
  });

  const editorRef = useRef<HTMLTextAreaElement>(null);

  const updateHeight = useCallback(() => {
    if (fullHeight) return;
    const editor = editorRef.current!;
    editor.style.height = "auto";
    editor.style.height = editor.scrollHeight + "px";
  }, [fullHeight])

  useEffect(() => {
    if (!fullHeight) {
      if (editorRef.current && !fullHeight) {
        editorRef.current.style.height = fullHeight ? "calc(100% - 32px)" : "auto";
        editorRef.current.addEventListener("input", ()=> {
          updateHeight();
        });
      }
    }
  }, [fullHeight, updateHeight]);

  const handlePaste = useCallback((e: React.ClipboardEvent) => {
    const items = e.clipboardData?.items;
    if(items && items.length === 1) {
      const item = items[0];
      if (item.type.startsWith('image/')) {
        e.preventDefault();
        const file = item.getAsFile();
        const reader = new FileReader();
        const editor = editorRef.current!;
        const start = editor.selectionStart;
        const end = editor.selectionEnd;
        reader.onload = async () => {
          const canceler = showLoadingDialog();
          const id = await network.uploadFile(file!);
          const url = `![image](${app.server}/api/file/download/${id})`;
          setState(prev => ({
            ...prev,
            text: prev.text.slice(0, start) + url + prev.text.slice(end)
          }));
          updateHeight();
          editor.selectionStart = start + url.length;
          editor.selectionEnd = start + url.length;
          canceler();
        }
        reader.readAsDataURL(file!);
      }
    }
  }, [updateHeight]);

  const uploadImage = useCallback(async () => {
    const editor = editorRef.current!;
    const start = editor.selectionStart;
    const end = editor.selectionEnd;
    setState(prevState => ({...prevState, isUploadingImage: true}));
    const input = document.createElement("input");
    input.type = "file";
    input.accept = "image/*";
    let isClicked = false;
    input.onchange = async () => {
      if(isClicked) return;
      isClicked = true;
      try {
        const file = input.files?.item(0);
        const id = await network.uploadFile(file!);
        const url = `![image](${app.server}/api/file/download/${id})`;
        setState(prev => ({
          ...prev,
          text: prev.text.slice(0, start) + url + prev.text.slice(end)
        }));
        editor.focus();
        editor.selectionStart = start + url.length;
        editor.selectionEnd = start + url.length;
        updateHeight();
      }
      catch (e: any) {
        showMessage({text: e.toString()});
      }
      finally {
        setState(prevState => ({...prevState, isUploadingImage: false}));
      }
    }
    input.click();
    input.oncancel = () => setState(prevState => ({...prevState, isUploadingImage: false}));
  }, [updateHeight]);

  return <div className={`w-full ${fullHeight ? "h-full" : ""} border-b px-3 pt-4 pb-2`}>
        <textarea
          placeholder={translate("Write down your thoughts")}
          className={"w-full focus:outline-none min-h-6 resize-none px-2"}
          ref={editorRef}
          onPaste={handlePaste}
          value={state.text}
          style={{height: fullHeight ? "calc(100% - 32px)" : undefined}}
          onChange={(v) => {
            onChanged({...state, text: v.target.value});
            setState({...state, text: v.target.value});
          }}></textarea>
      <div className={"h-8 w-full flex flex-row"}>
        <TapRegion onPress={() => {
          setState({...state, isPublic: !state.isPublic});
          onChanged({...state, isPublic: !state.isPublic});
        }} borderRadius={12}>
          <div className={"h-8 flex flex-row items-center justify-center text-primary text-sm px-2"}>
            {state.isPublic ? <MdPublic size={18}/> : <MdLock size={18}/>}
            <span className={"w-2"}></span>
            <Tr>{state.isPublic ? "Public" : "Private"}</Tr>
          </div>
        </TapRegion>
        <IconButton onPress={uploadImage} isLoading={state.isUploadingImage}>
          <MdOutlineImage/>
        </IconButton>
        <IconButton onPress={() => {
          window.open("https://github.com/usememento/Memento/blob/master/doc/ContentSyntax.md")
        }}>
          <MdOutlineInfo/>
        </IconButton>
        <div className={"flex-grow"}></div>
        <Button className={"h-8 rounded-2xl"} color={"primary"} onClick={async () => {
          if (state.isUploading) return;
          setState({...state, isUploading: true});
          try {
            await submit();
            setState(prevState => ({...prevState, text: ""}));
            showMessage({text: translate("Post created")});
            if (!fullHeight) {
              updateHeight();
            }
          } catch (e: any) {
            showMessage({text: e.toString()});
          } finally {
            setState(prevState => ({...prevState, isUploading: false}));
          }
        }}>{state.isUploading ? <Loading size={18}></Loading> : <Tr>Submit</Tr>}</Button>
      </div>
  </div>
}