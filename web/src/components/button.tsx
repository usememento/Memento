import {ReactNode} from "react";
import {Spinner} from "@nextui-org/react";

interface TapRegionProps {
    onPress: () => void;
    children: ReactNode;
    borderRadius?: number;
    lighter?: boolean;
}

export function TapRegion({onPress, children, borderRadius = 0, lighter}: TapRegionProps) {
    return <div onClick={(e) => {
        e.stopPropagation();
        onPress();
    }} style={{borderRadius: borderRadius}}
                className={`cursor-pointer hover:bg-content2 active:bg-content3 duration-200 ${lighter ? "hover:bg-opacity-60 active:bg-opacity-60" : ''}`}>
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
            {(isLoading ?? false) ? <Spinner size={"sm"}/> : children}
        </div>
    </TapRegion>
}