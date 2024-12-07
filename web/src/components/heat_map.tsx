import {HeatMapData} from "../network/model.ts";
import {ReactNode, useEffect, useRef, useState} from "react";
import {network} from "../network/network.ts";
import {Loading} from "./message.tsx";

export default function HeatMapWidget({username, showStatistics}: { username: string, showStatistics?: boolean }) {
    const [data, setData] = useState<HeatMapData | null>(null)

    useEffect(() => {
        network.getHeatMap(username).then(setData)
    }, [username]);

    if (!data) {
        return <div className={"w-full h-20 flex items-center justify-center"}>
            <Loading/>
        </div>
    } else {
        return <HeatMap data={data} showStatistics={showStatistics}/>
    }
}

interface HeatMapProps {
    data: HeatMapData;
    showStatistics?: boolean;
}

const SQUARE_SIZE = 12.0;
const PADDING = 2.0;
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const mainColor = "#1a73e8"; // Replace with your app's main color

function HeatMap({data, showStatistics = true}: HeatMapProps) {
    const containerRef = useRef<HTMLDivElement>(null);
    const [maxColumns, setMaxColumns] = useState(0);

    useEffect(() => {
        const updateMaxColumns = () => {
            if (containerRef.current) {
                const width = containerRef.current.offsetWidth;
                setMaxColumns(Math.min(Math.floor(width / (SQUARE_SIZE + PADDING * 2)), 52));
            }
        };

        updateMaxColumns();
        window.addEventListener('resize', updateMaxColumns);
        return () => window.removeEventListener('resize', updateMaxColumns);
    }, []);

    const buildOneDay = (time: string, count: number, primary: string) => {
        const opacity = clamp(count, 0, 5) * 0.16 + 0.2;
        const backgroundColor = count === 0 ? undefined : `${primary}${Math.round(opacity * 255).toString(16).padStart(2, '0')}`;
        return (
            <div
                className={"bg-content2 tooltip"}
                style={{
                    width: SQUARE_SIZE,
                    height: SQUARE_SIZE,
                    backgroundColor: backgroundColor,
                    borderRadius: 2,
                    margin: PADDING,
                }}
                key={time}
            >
                <span className={"tooltipText"}>{`${time}\n${count} Posts`}</span>
            </div>
        );
    };

    const buildColumn = (startDate: Date, columnIndex: number, monthInfo: Map<number, number>) => {
        const children = [];

        for (let i = 0; i < 7; i++) {
            const date = new Date(startDate);
            date.setDate(date.getDate() + i);

            if (date.getDate() === 1) {
                monthInfo.set(date.getMonth() + 1, columnIndex);
            }

            const key = date.toISOString().substring(0, 10);
            const count = data.map[key] || 0;
            const time = `${date.getMonth() + 1}-${date.getDate()}`;

            children.push(buildOneDay(time, count, mainColor));
        }

        return (
            <div style={{display: 'flex', flexDirection: 'column'}} key={startDate.toISOString()}>
                {children}
            </div>
        );
    };

    const buildMonthInfo = (monthInfo: Map<number, number>) => {
        const children: ReactNode[] = [];
        let lastIndex = -1;

        console.log(monthInfo);

        Array.from(monthInfo.entries()).sort((a, b) => b[0] - a[0]).forEach(([month, columnIndex]) => {
            const monthName = MONTHS[month - 1];
            const columns = columnIndex - lastIndex;

            children.push(
                <div
                    key={month}
                    style={{
                        width: (SQUARE_SIZE + PADDING * 2) * columns,
                        textAlign: 'left',
                        fontSize: 12,
                    }}
                >
                    {monthName}
                </div>
            );

            lastIndex = columnIndex;
        });

        return (
            <div className={"flex flex-row w-full"}>
                {[<div className={"flex-grow"} key={"0"}/>, ...children.reverse(), <div key={"1"} style={{
                    width: (containerRef.current!.clientWidth-1 - (SQUARE_SIZE + PADDING * 2) * (maxColumns)) / 2 - PADDING,
                }}/>]}
            </div>
        );
    };

    const buildStatistic = () => {
        const StatItem = ({title, count}: { title: string; count: number }) => (
            <div style={{padding: '0 8px'}}>
                <div style={{fontSize: 16, fontWeight: 'bold'}} className={"text-center"}>{count}</div>
                <div style={{fontSize: 12}}>{title}</div>
            </div>
        );

        return (
            <div className={"px-2"} style={{display: 'flex', justifyContent: 'space-between', width: "100%"}}>
                <StatItem title="Posts" count={data.memos} key={0}/>
                <StatItem title="Days" count={Object.getOwnPropertyNames(data.map).length} key={1}/>
                <StatItem title="Likes" count={data.likes} key={2}/>
            </div>
        );
    };

    const renderHeatMap = () => {
        if (!maxColumns) return null;

        const currentDate = new Date();
        if (currentDate.getDay() !== 0) {
            currentDate.setDate(currentDate.getDate() - currentDate.getDay());
        }

        const columns = [];
        const monthInfo = new Map<number, number>();

        for (let i = 0; i < maxColumns; i++) {
            columns.push(buildColumn(currentDate, i, monthInfo));
            currentDate.setDate(currentDate.getDate() - 7);
        }

        return (
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
                {showStatistics && (
                    <>
                        {buildStatistic()}
                        <div style={{height: 8}}/>
                    </>
                )}
                <div style={{display: 'flex', flexDirection: 'row-reverse'}}>
                    {columns}
                </div>
                <div style={{height: 8}}/>
                {buildMonthInfo(monthInfo)}
            </div>
        );
    };

    return (
        <div className={"w-full px-2"}>
            <div ref={containerRef} className={"w-full py-4"}>
                {renderHeatMap()}
            </div>
        </div>
    );
}

function clamp(value: number, min: number, max: number) {
    return Math.min(Math.max(value, min), max);
}