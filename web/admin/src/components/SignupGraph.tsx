import React, { useState } from 'react';

type TimespanOption = `week` | `month` | `3 months` | `6 months` | `year`;

interface Signup {
  date: string;
  status: string;
  email: string;
}

interface SignupGraphProps {
  signups: Signup[];
}

interface PeriodData {
  time: Date;
  startTime: Date;
  numSignups: number;
  signups: Signup[];
  isGrouped: boolean;
}

const isActive = (status: string): boolean => status === `active`;

const isOnboarded = (status: string): boolean => status === `onboarded`;

const SignupGraph: React.FC<SignupGraphProps> = ({ signups }) => {
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

  const getPeriodsData = (offsetPeriods: number): PeriodData[] => {
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
      const periodSignups = signups.filter((signup) => {
        const signupDate = new Date(signup.date);
        signupDate.setHours(0, 0, 0, 0);
        const startDate = new Date(start);
        startDate.setHours(0, 0, 0, 0);
        const endDate = new Date(end);
        endDate.setHours(23, 59, 59, 999);
        return signupDate >= startDate && signupDate <= endDate;
      });
      return {
        time: end,
        startTime: start,
        numSignups: periodSignups.length,
        signups: periodSignups,
        isGrouped,
      };
    });
  };

  const signupData = getPeriodsData(0);
  const lastPeriodSignupData = getPeriodsData(1);

  const thisPeriodSignups = signupData.reduce((acc, cur) => acc + cur.numSignups, 0);
  const lastPeriodSignups = lastPeriodSignupData.reduce(
    (acc, cur) => acc + cur.numSignups,
    0,
  );

  const percentChange =
    lastPeriodSignups > 0
      ? Math.round(((thisPeriodSignups - lastPeriodSignups) / lastPeriodSignups) * 100)
      : 0;

  const maxSignups = Math.max(...signupData.map((d) => d.numSignups), 1);

  const hoveredData = hoveredIndex !== null ? signupData[hoveredIndex] : null;

  const graphHeight = 180;

  return (
    <div className="bg-slate-50 rounded-xl border border-slate-100 flex flex-col overflow-hidden">
      <div className="p-4 pb-2 relative">
        <div className="flex items-end gap-px" style={{ height: graphHeight }}>
          {signupData.map((data, index) => {
            const barHeight =
              maxSignups > 0
                ? Math.max(
                    (data.numSignups / maxSignups) * graphHeight,
                    data.numSignups > 0 ? 4 : 2,
                  )
                : 2;
            const isHovered = hoveredIndex === index;

            return (
              <div
                key={data.time.toISOString() + timespan}
                className="flex-1 flex items-end cursor-pointer px-px"
                onMouseEnter={() => setHoveredIndex(index)}
                onMouseLeave={() => setHoveredIndex(null)}
              >
                <div
                  className={`w-full rounded-t-sm transition-all duration-150 bg-gradient-to-t from-brand-violet to-brand-fuchsia ${
                    isHovered ? `shadow-lg shadow-brand-violet/40 scale-x-110` : ``
                  }`}
                  style={{ height: barHeight }}
                />
              </div>
            );
          })}
        </div>

        {hoveredData && hoveredIndex !== null && (
          <div
            className="absolute z-30 bg-white shadow-xl rounded-xl p-4 w-56 border border-slate-200 pointer-events-none"
            style={{
              top: 8,
              left: `calc(${((hoveredIndex + 0.5) / signupData.length) * 100}% + 16px)`,
              transform:
                hoveredIndex > signupData.length / 2
                  ? `translateX(-100%)`
                  : `translateX(0)`,
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
              {hoveredData.numSignups || `No`} new signup
              {hoveredData.numSignups !== 1 && `s`}
            </span>
            {hoveredData.signups.length > 0 && (
              <ul className="mt-2 space-y-0.5 max-h-32 overflow-y-auto">
                {hoveredData.signups.map((signup, i) => (
                  <li
                    className="text-xs text-slate-500 flex gap-1.5 items-center"
                    key={signup.email + i}
                  >
                    <div
                      className={`w-2 h-2 rounded-full shrink-0 ${
                        isActive(signup.status)
                          ? `bg-emerald-500`
                          : isOnboarded(signup.status)
                            ? `bg-amber-500`
                            : `bg-slate-300`
                      }`}
                    />
                    <span className="truncate">{signup.email}</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
      </div>

      <div className="py-4 px-5 flex justify-between items-center gap-4 border-t border-slate-200 bg-white">
        <div className="flex flex-col">
          <span className="text-slate-500 text-sm">{thisPeriodSignups} new signups</span>
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
                    ? `text-white bg-gradient-to-r from-brand-violet to-brand-fuchsia shadow-md shadow-brand-violet/20`
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

export default SignupGraph;
