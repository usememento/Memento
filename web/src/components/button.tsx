import {ReactNode} from "react";
import {Loading} from "./message.tsx";

interface TapRegionProps {
    onPress: () => void;
    children: ReactNode;
    borderRadius?: number;
    lighter?: boolean;
    className?: string;
}

export function TapRegion({onPress, children, borderRadius = 0, lighter, className}: TapRegionProps) {
    return <div onClick={(e) => {
        e.stopPropagation();
        onPress();
    }} style={{borderRadius: borderRadius}}
                className={`cursor-pointer hover:bg-content2 active:bg-content3 duration-200 ${lighter ? "hover:bg-opacity-60 active:bg-opacity-60" : ''} ${className}`}>
        {children}
    </div>
}

export function IconButton({onPress, children, primary, isLoading}: {
    onPress: () => void,
    children: ReactNode,
    primary?: boolean,
    isLoading?: boolean
}) {
    return <TapRegion onPress={onPress} borderRadius={9999}>
        <div
            className={`w-8 h-8 flex flex-row items-center justify-center ${(primary ?? true) ? "text-primary" : null} text-lg`}>
            {(isLoading ?? false) ? <Loading size={18}/> : children}
        </div>
    </TapRegion>
}