import {ReactNode} from "react";

interface TapRegionProps {
    onPress: () => void;
    children: ReactNode;
    borderRadius?: number;
}

export function TapRegion({onPress, children, borderRadius = 0}: TapRegionProps) {
    return <div onClick={onPress} style={{borderRadius: borderRadius}}
        className={"cursor-pointer hover:bg-content2 active:bg-content3 duration-200"}>
        {children}
    </div>
}