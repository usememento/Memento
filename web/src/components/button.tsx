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

export function IconButton({onPress, children}: { onPress: () => void, children: ReactNode }) {
    return <TapRegion onPress={onPress} borderRadius={9999}>
        <div className={"w-8 h-8 flex flex-row items-center justify-center text-primary text-2xl"}>
            {children}
        </div>
    </TapRegion>
}