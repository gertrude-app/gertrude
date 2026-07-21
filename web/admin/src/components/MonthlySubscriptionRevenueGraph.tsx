import React, { useState } from 'react';
import type { T } from '@shared/pairql/admin';

type RangeOption = `6m` | `12m` | `all`;

type MonthData = T.SubscriptionsOverview.Output[`monthlySubscriptionRevenue`][number];

interface MonthlySubscriptionRevenueGraphProps {
  months: MonthData[];
}

const formatDollars = (cents: number): string => {
  const dollars = cents / 100;
  return dollars.toLocaleString(`en-US`, {
    style: `currency`,
    currency: `USD`,
    minimumFractionDigits: dollars % 1 === 0 ? 0 : 2,
    maximumFractionDigits: dollars % 1 === 0 ? 0 : 2,
  });
};

const dateForMonth = (month: string): Date => new Date(`${month}-01T12:00:00`);

const formatMonth = (month: string): string =>
  dateForMonth(month).toLocaleDateString(`en-US`, { month: `short`, year: `numeric` });

const formatTickMonth = (month: string): string =>
  dateForMonth(month).toLocaleDateString(`en-US`, { month: `short` });

const MonthlySubscriptionRevenueGraph: React.FC<MonthlySubscriptionRevenueGraphProps> = ({
  months,
}) => {
  const [range, setRange] = useState<RangeOption>(`all`);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const sortedMonths = [...months].sort((a, b) => a.month.localeCompare(b.month));
  const visibleMonths =
    range === `all` ? sortedMonths : sortedMonths.slice(range === `6m` ? -6 : -12);
  const totalCents = visibleMonths.reduce((sum, month) => sum + month.centsCollected, 0);
  const maxCents = Math.max(...visibleMonths.map((month) => month.centsCollected), 1);
  const graphHeight = 180;
  const hoveredMonth = hoveredIndex !== null ? visibleMonths[hoveredIndex] : null;
  const labelStride =
    visibleMonths.length <= 12 ? 1 : Math.ceil(visibleMonths.length / 8);

  return (
    <div className="bg-slate-50 rounded-xl border border-slate-100 flex flex-col overflow-hidden">
      <div className="p-4 pb-3 relative">
        <div className="mb-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500">
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-emerald-500" />
            Full Plan
          </span>
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-violet-500" />
            Medium Plan
          </span>
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-sky-500" />
            Light Plan
          </span>
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-slate-300" />
            Other
          </span>
        </div>

        <div className="flex items-end gap-1" style={{ height: graphHeight }}>
          {visibleMonths.map((month, index) => {
            const barHeight = Math.max(
              (month.centsCollected / maxCents) * graphHeight,
              month.centsCollected > 0 ? 4 : 2,
            );
            const fullPlanHeight =
              month.centsCollected > 0
                ? (month.fullPlanCents / month.centsCollected) * barHeight
                : 0;
            const mediumPlanHeight =
              month.centsCollected > 0
                ? (month.mediumPlanCents / month.centsCollected) * barHeight
                : 0;
            const lightPlanHeight =
              month.centsCollected > 0
                ? (month.lightPlanCents / month.centsCollected) * barHeight
                : 0;
            const otherHeight =
              month.centsCollected > 0
                ? Math.max(
                    0,
                    barHeight - fullPlanHeight - mediumPlanHeight - lightPlanHeight,
                  )
                : barHeight;

            return (
              <div
                key={`${month.month}-${range}`}
                className="flex-1 flex items-end cursor-pointer"
                onMouseEnter={() => setHoveredIndex(index)}
                onMouseLeave={() => setHoveredIndex(null)}
              >
                <div
                  className={`w-full rounded-t-sm overflow-hidden flex flex-col-reverse gap-px ${
                    month.centsCollected > 0 ? `` : `bg-slate-200`
                  }`}
                  style={{ height: barHeight }}
                >
                  {month.centsCollected > 0 && (
                    <>
                      {month.fullPlanCents > 0 && (
                        <div
                          className="w-full bg-emerald-500"
                          style={{ height: fullPlanHeight }}
                        />
                      )}
                      {month.mediumPlanCents > 0 && (
                        <div
                          className="w-full bg-violet-500"
                          style={{ height: mediumPlanHeight }}
                        />
                      )}
                      {month.lightPlanCents > 0 && (
                        <div
                          className="w-full bg-sky-500"
                          style={{ height: lightPlanHeight }}
                        />
                      )}
                      {month.otherCents > 0 && (
                        <div
                          className="w-full bg-slate-300"
                          style={{ height: otherHeight }}
                        />
                      )}
                    </>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <div className="mt-2 flex gap-1 text-[10px] text-slate-400">
          {visibleMonths.map((month, index) => (
            <div key={month.month} className="flex-1 text-center truncate">
              {index % labelStride === 0 || index === visibleMonths.length - 1
                ? formatTickMonth(month.month)
                : ``}
            </div>
          ))}
        </div>

        {hoveredMonth && hoveredIndex !== null && (
          <div
            className="absolute z-30 bg-white shadow-xl rounded-xl p-4 border border-slate-200 pointer-events-none w-56"
            style={{
              top: 8,
              left: `calc(${((hoveredIndex + 0.5) / visibleMonths.length) * 100}% + 16px)`,
              transform:
                hoveredIndex > visibleMonths.length / 2
                  ? `translateX(-100%)`
                  : `translateX(0)`,
            }}
          >
            <span className="text-slate-400 text-xs font-medium block">
              {formatMonth(hoveredMonth.month)}
            </span>
            <span className="text-lg font-display font-semibold text-slate-900">
              {formatDollars(hoveredMonth.centsCollected)}
            </span>
            <div className="mt-2 space-y-1 text-xs text-slate-500">
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-sm bg-emerald-500" />
                  Full Plan
                </span>
                <span className="font-medium text-slate-700">
                  {formatDollars(hoveredMonth.fullPlanCents)}
                </span>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-sm bg-violet-500" />
                  Medium Plan
                </span>
                <span className="font-medium text-slate-700">
                  {formatDollars(hoveredMonth.mediumPlanCents)}
                </span>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-sm bg-sky-500" />
                  Light Plan
                </span>
                <span className="font-medium text-slate-700">
                  {formatDollars(hoveredMonth.lightPlanCents)}
                </span>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="inline-flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-sm bg-slate-300" />
                  Other
                </span>
                <span className="font-medium text-slate-700">
                  {formatDollars(hoveredMonth.otherCents)}
                </span>
              </div>
            </div>
            <span className="text-xs text-slate-500 block mt-2">
              {hoveredMonth.paidInvoices.toLocaleString()} paid invoice
              {hoveredMonth.paidInvoices !== 1 && `s`}
            </span>
          </div>
        )}
      </div>

      <div className="py-3 sm:py-4 px-4 sm:px-5 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 border-t border-slate-200 bg-white">
        <div className="flex items-center sm:items-start gap-3 sm:gap-0 sm:flex-col">
          <span className="text-slate-500 text-sm">Total revenue</span>
          <span className="text-2xl font-display font-semibold text-emerald-600">
            {formatDollars(totalCents)}
          </span>
        </div>
        <div className="flex flex-wrap gap-1 items-center">
          {(
            [
              [`6m`, `6m`],
              [`12m`, `12m`],
              [`all`, `All-time`],
            ] as const
          ).map(([value, label]) => (
            <button
              key={value}
              onClick={() => setRange(value)}
              className={`px-2.5 sm:px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-all ${
                range === value
                  ? `text-white bg-emerald-500 shadow-md shadow-emerald-500/20`
                  : `text-slate-500 hover:text-slate-700 hover:bg-slate-100`
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default MonthlySubscriptionRevenueGraph;
