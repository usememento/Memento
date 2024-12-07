export default function TestPage() {
    return (
        <div className={"w-full h-full flex"}>
            <div className={"flex-grow bg-red-100 min-w-0 overflow-x-hidden"}>
                <p style={{ overflowWrap: 'break-word', wordBreak: 'break-all' }}>
                    1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
                </p>
            </div>
            <div className={"w-80"}></div>
        </div>
    );
}