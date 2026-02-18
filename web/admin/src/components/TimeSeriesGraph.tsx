import React, { useState } from 'react';

type TimespanOption = `week` | `month` | `3 months` | `6 months` | `year`;

interface DataItem {
  date: string;
  status: string;
  label: string;
}

interface StatusConfig {
  isSuccess: (status: string) => boolean;
  isWarning: (status: string) => boolean;
  isInfo?: (status: string) => boolean;
}

interface TimeSeriesGraphProps<T extends DataItem> {
  items: T[];
  itemLabel: string;
  gradient: `violet` | `blue` | `green`;
  statusConfig: StatusConfig;
  twoColumnTooltip?: boolean;
}

interface PeriodData<T extends DataItem> {
  time: Date;
  startTime: Date;
  count: number;
  items: T[];
  isGrouped: boolean;
}

const TimeSeriesGraph = <T extends DataItem>({
  items,
  itemLabel,
  gradient,
  statusConfig,
  twoColumnTooltip = false,
}: TimeSeriesGraphProps<T>): React.ReactElement => {
  const [timespan, setTimespan] = useState<TimespanOption>(`month`);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const periodConfig = (() => {
    switch (timespan) {
      case `week`:
        return { numPeriods: 7, daysPerPeriod: 1 };
      case `month`:
        return { numPeriods: 30, daysPerPeriod: 1 };
      case `3 months`:
        return { numPeriods: 90, daysPerPeriod: 1 };
      case `6 months`:
        return { numPeriods: 60, daysPerPeriod: 3 };
      case `year`:
        return { numPeriods: 52, daysPerPeriod: 7 };
    }
  })();

  const { numPeriods, daysPerPeriod } = periodConfig;
  const isGrouped = daysPerPeriod > 1;

  const now = new Date();

  const getPeriodsData = (offsetPeriods: number): PeriodData<T>[] => {
    const periods: { start: Date; end: Date }[] = [];
    const totalDays = numPeriods * daysPerPeriod;

    for (let i = 0; i < numPeriods; i++) {
      const periodEnd = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() - i * daysPerPeriod - offsetPeriods * totalDays,
      );
      const periodStart = new Date(
        periodEnd.getFullYear(),
        periodEnd.getMonth(),
        periodEnd.getDate() - (daysPerPeriod - 1),
      );
      periods.push({ start: periodStart, end: periodEnd });
    }

    return periods.reverse().map(({ start, end }) => {
      const periodItems = items.filter((item) => {
        const itemDate = new Date(item.date);
        itemDate.setHours(0, 0, 0, 0);
        const startDate = new Date(start);
        startDate.setHours(0, 0, 0, 0);
        const endDate = new Date(end);
        endDate.setHours(23, 59, 59, 999);
        return itemDate >= startDate && itemDate <= endDate;
      });
      return {
        time: end,
        startTime: start,
        count: periodItems.length,
        items: periodItems,
        isGrouped,
      };
    });
  };

  const data = getPeriodsData(0);
  const lastPeriodData = getPeriodsData(1);

  const thisPeriodCount = data.reduce((acc, cur) => acc + cur.count, 0);
  const lastPeriodCount = lastPeriodData.reduce((acc, cur) => acc + cur.count, 0);

  const percentChange =
    lastPeriodCount > 0
      ? Math.round(((thisPeriodCount - lastPeriodCount) / lastPeriodCount) * 100)
      : 0;

  const maxCount = Math.max(...data.map((d) => d.count), 1);

  const hoveredData = hoveredIndex !== null ? data[hoveredIndex] : null;

  const graphHeight = 180;

  const gradientClasses = {
    violet: `from-brand-violet to-brand-fuchsia`,
    blue: `from-sky-400 to-blue-500`,
    green: `from-emerald-400 to-green-500`,
  };

  const shadowClasses = {
    violet: `shadow-brand-violet/40`,
    blue: `shadow-sky-500/40`,
    green: `shadow-emerald-500/40`,
  };

  const buttonActiveClasses = {
    violet: `from-brand-violet to-brand-fuchsia shadow-brand-violet/20`,
    blue: `from-sky-400 to-blue-500 shadow-sky-500/20`,
    green: `from-emerald-400 to-green-500 shadow-emerald-500/20`,
  };

  return (
    <div className="bg-slate-50 rounded-xl border border-slate-100 flex flex-col overflow-hidden">
      <div className="p-4 pb-2 relative">
        <div className="flex items-end gap-px" style={{ height: graphHeight }}>
          {data.map((periodData, index) => {
            const barHeight =
              maxCount > 0
                ? Math.max(
                    (periodData.count / maxCount) * graphHeight,
                    periodData.count > 0 ? 4 : 2,
                  )
                : 2;
            const isHovered = hoveredIndex === index;

            return (
              <div
                key={periodData.time.toISOString() + timespan}
                className="flex-1 flex items-end cursor-pointer px-px"
                onMouseEnter={() => setHoveredIndex(index)}
                onMouseLeave={() => setHoveredIndex(null)}
              >
                <div
                  className={`w-full rounded-t-sm transition-all duration-150 bg-gradient-to-t ${gradientClasses[gradient]} ${
                    isHovered ? `shadow-lg ${shadowClasses[gradient]} scale-x-110` : ``
                  }`}
                  style={{ height: barHeight }}
                />
              </div>
            );
          })}
        </div>

        {hoveredData && hoveredIndex !== null && (
          <div
            className={`absolute z-30 bg-white shadow-xl rounded-xl p-4 border border-slate-200 pointer-events-none ${
              twoColumnTooltip ? `w-96` : `w-56`
            }`}
            style={{
              top: 8,
              left: `calc(${((hoveredIndex + 0.5) / data.length) * 100}% + 16px)`,
              transform:
                hoveredIndex > data.length / 2 ? `translateX(-100%)` : `translateX(0)`,
            }}
          >
            <span className="text-slate-400 text-xs font-medium block">
              {hoveredData.isGrouped
                ? `${hoveredData.startTime.toLocaleDateString(`en-US`, { month: `short`, day: `numeric` })} – ${hoveredData.time.toLocaleDateString(`en-US`, { month: `short`, day: `numeric` })}`
                : hoveredData.time.toLocaleDateString(`en-US`, {
                    weekday: `short`,
                    month: `short`,
                    day: `numeric`,
                  })}
            </span>
            <span className="text-lg font-display font-semibold text-slate-900">
              {hoveredData.count || `No`} {itemLabel}
              {hoveredData.count !== 1 && `s`}
            </span>
            {hoveredData.items.length > 0 && (
              <ul
                className={`mt-2 max-h-32 overflow-y-auto ${
                  twoColumnTooltip ? `flex flex-wrap gap-x-3 gap-y-0.5` : `space-y-0.5`
                }`}
              >
                {hoveredData.items.map((item, i) => (
                  <li
                    className={`text-xs text-slate-500 flex gap-1.5 items-center ${
                      twoColumnTooltip ? `w-[calc(33.33%-8px)]` : ``
                    }`}
                    key={item.label + i}
                  >
                    <div
                      className={`w-2 h-2 rounded-full shrink-0 ${
                        statusConfig.isSuccess(item.status)
                          ? `bg-emerald-500`
                          : statusConfig.isInfo?.(item.status)
                            ? `bg-sky-500`
                            : statusConfig.isWarning(item.status)
                              ? `bg-amber-500`
                              : `bg-slate-300`
                      }`}
                    />
                    <span className="truncate">{item.label}</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>

      <div className="py-4 px-5 flex justify-between items-center gap-4 border-t border-slate-200 bg-white">
        <div className="flex flex-col">
          <span className="text-slate-500 text-sm">
            {thisPeriodCount} {itemLabel}
            {thisPeriodCount !== 1 && `s`}
          </span>
          <span
            className={`text-2xl font-display font-semibold ${
              percentChange >= 0 ? `text-emerald-600` : `text-rose-500`
            }`}
          >
            {percentChange >= 0 && `+`}
            {percentChange}%
          </span>
        </div>
        <div className="flex gap-1 items-center">
          {([`week`, `month`, `3 months`, `6 months`, `year`] as TimespanOption[]).map(
            (option) => (
              <button
                key={option}
                onClick={() => setTimespan(option)}
                className={`capitalize px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
                  timespan === option
                    ? `text-white bg-gradient-to-r ${buttonActiveClasses[gradient]} shadow-md`
                    : `text-slate-500 hover:text-slate-700 hover:bg-slate-100`
                }`}
              >
                {option}
              </button>
            ),
          )}
        </div>
        <div className="w-32" />
      </div>
    </div>
  );
};

export default TimeSeriesGraph;
