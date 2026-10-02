import React, { useState } from 'react';
import type { T } from '@shared/pairql/admin';
import {
  monthlyRevenueGrowthForecast,
  projectedMonthlyRevenue,
} from '../lib/monthlyRevenueProjection';

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

const formatCompactDollars = (cents: number): string =>
  (cents / 100).toLocaleString(`en-US`, {
    style: `currency`,
    currency: `USD`,
    notation: `compact`,
    minimumFractionDigits: 0,
    maximumFractionDigits: 1,
  });

const trendOptions = [
  { lookbackMonths: 3, color: `text-amber-600`, dash: `3 3` },
  { lookbackMonths: 6, color: `text-slate-500`, dash: `5 4` },
  { lookbackMonths: 12, color: `text-rose-500`, dash: `9 4` },
] as const;

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

  const now = new Date();
  const forecast = monthlyRevenueGrowthForecast(months, now);
  const currentMonth = forecast.currentMonth;
  const trends = trendOptions.flatMap((option) => {
    const trendForecast =
      option.lookbackMonths === 6
        ? forecast
        : monthlyRevenueGrowthForecast(months, now, option.lookbackMonths);
    const endpoint = trendForecast.months.at(-1);
    return trendForecast.baseline && endpoint && endpoint.projectedCents !== null
      ? [{ ...option, forecast: trendForecast, endpointCents: endpoint.projectedCents }]
      : [];
  });
  const sortedMonths = months
    .filter((month) => month.month <= currentMonth)
    .sort((a, b) => a.month.localeCompare(b.month));
  const visibleMonths =
    range === `all` ? sortedMonths : sortedMonths.slice(range === `6m` ? -6 : -12);
  const totalCents = visibleMonths.reduce((sum, month) => sum + month.centsCollected, 0);
  const chartMonths =
    months.length === 0
      ? []
      : [
          ...visibleMonths
            .filter((month) => month.month < currentMonth)
            .map((month) => ({ month: month.month, actual: month })),
          ...forecast.months.map((month) => ({
            month: month.month,
            actual: visibleMonths.find((actual) => actual.month === month.month),
          })),
        ];
  const projections = chartMonths.map(({ actual }) =>
    actual ? projectedMonthlyRevenue(actual.month, actual.centsCollected, now) : null,
  );
  const maxCents = Math.max(
    ...chartMonths.flatMap(({ actual }, index) => [
      actual?.centsCollected ?? 0,
      projections[index] ?? 0,
    ]),
    ...trends.flatMap((trend) =>
      trend.forecast.months.map((month) => month.projectedCents ?? 0),
    ),
    1,
  );
  const graphHeight = 180;
  const plotHeight = graphHeight + 56;
  const baselineIndex = chartMonths.findIndex(
    (month) => month.month === trends[0]?.forecast.baseline?.month,
  );
  const xForIndex = (index: number): number => ((index + 0.5) / chartMonths.length) * 100;
  const plottedTrends =
    baselineIndex < 0
      ? []
      : trends.map((trend) => ({
          ...trend,
          endpointHeight: (trend.endpointCents / maxCents) * graphHeight,
          points: [
            trend.forecast.baseline?.centsCollected ?? 0,
            ...trend.forecast.months.map((month) => month.projectedCents ?? 0),
          ]
            .map(
              (cents, index) =>
                `${xForIndex(baselineIndex + index) * 10},${plotHeight - (cents / maxCents) * graphHeight}`,
            )
            .join(` `),
        }));
  let previousLabelBottom = -20;
  const endpointLabels = [...plottedTrends]
    .sort((a, b) => a.endpointHeight - b.endpointHeight)
    .map((trend) => {
      const labelBottom = Math.max(0, trend.endpointHeight - 8, previousLabelBottom + 20);
      previousLabelBottom = labelBottom;
      return { ...trend, labelBottom };
    });
  const hoveredSlot = hoveredIndex !== null ? chartMonths[hoveredIndex] : null;
  const hoveredMonth = hoveredSlot?.actual;
  const hoveredProjection = hoveredIndex !== null ? projections[hoveredIndex] : null;
  const hoveredTrends = plottedTrends.flatMap((trend) => {
    const month = trend.forecast.months.find(
      (month) => month.month === hoveredSlot?.month,
    );
    return month && month.projectedCents !== null
      ? [{ ...trend, cents: month.projectedCents }]
      : [];
  });
  const labelStride = chartMonths.length <= 12 ? 1 : Math.ceil(chartMonths.length / 8);

  return (
    <div
      className={`bg-slate-50 rounded-xl border border-slate-100 flex flex-col overflow-visible ${
        plottedTrends.length > 0 ? `mr-12` : ``
      }`}
    >
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
          <span className="inline-flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-slate-200" />
            Current pace
          </span>
          {plottedTrends.map((trend) => (
            <span
              key={trend.lookbackMonths}
              className={`inline-flex items-center gap-1.5 ${trend.color}`}
              title={`Average monthly revenue change over the last ${trend.lookbackMonths} completed months`}
            >
              <span className="w-4 border-t-2 border-dashed border-current" />
              {trend.lookbackMonths}m avg
            </span>
          ))}
        </div>

        <div className="relative" style={{ height: plotHeight }}>
          <div
            className="absolute inset-x-0 bottom-0 flex items-end"
            style={{ height: graphHeight }}
          >
            {chartMonths.map(({ month: monthKey, actual: month }, index) => {
              if (!month) {
                return (
                  <div
                    key={`${monthKey}-${range}`}
                    className="flex-1 min-w-0 h-full px-0.5 cursor-pointer"
                    onMouseEnter={() => setHoveredIndex(index)}
                    onMouseLeave={() => setHoveredIndex(null)}
                  />
                );
              }
              const barHeight = Math.max(
                (month.centsCollected / maxCents) * graphHeight,
                month.centsCollected > 0 ? 4 : 2,
              );
              const projectedHeight =
                ((projections[index] ?? 0) / maxCents) * graphHeight;
              const projectionHeight = Math.max(0, projectedHeight - barHeight);
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
                  className="flex-1 min-w-0 h-full px-0.5 flex flex-col justify-end cursor-pointer"
                  onMouseEnter={() => setHoveredIndex(index)}
                  onMouseLeave={() => setHoveredIndex(null)}
                >
                  {projectionHeight > 0 && (
                    <div
                      className="w-full rounded-t-sm bg-slate-200"
                      style={{ height: projectionHeight }}
                    />
                  )}
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
          {plottedTrends.length > 0 && (
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none"
              viewBox={`0 0 1000 ${plotHeight}`}
              preserveAspectRatio="none"
              role="img"
              aria-label="Revenue trend forecasts"
            >
              {plottedTrends.map((trend) => (
                <polyline
                  key={trend.lookbackMonths}
                  className={trend.color}
                  aria-label={`${trend.lookbackMonths}-month average revenue forecast`}
                  points={trend.points}
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeDasharray={trend.dash}
                  vectorEffect="non-scaling-stroke"
                />
              ))}
            </svg>
          )}
          {endpointLabels.map((trend) => (
            <React.Fragment key={trend.lookbackMonths}>
              <div
                className={`absolute w-1.5 h-1.5 rounded-full bg-current -translate-x-1/2 translate-y-1/2 pointer-events-none ${trend.color}`}
                style={{
                  left: `${xForIndex(chartMonths.length - 1)}%`,
                  bottom: trend.endpointHeight,
                }}
              />
              <div
                className={`absolute inline-flex items-center gap-1 rounded bg-slate-50/95 px-1 py-0.5 text-[10px] leading-3 font-semibold whitespace-nowrap pointer-events-none ${trend.color}`}
                style={{
                  left: `calc(${xForIndex(chartMonths.length - 1)}% + 8px)`,
                  bottom: trend.labelBottom,
                }}
              >
                <span className="opacity-70">{trend.lookbackMonths}m</span>
                <span>{formatCompactDollars(trend.endpointCents)}</span>
              </div>
            </React.Fragment>
          ))}
        </div>

        <div className="mt-2 flex text-[10px] text-slate-400">
          {chartMonths.map((month, index) => (
            <div key={month.month} className="flex-1 min-w-0 text-center truncate">
              {index % labelStride === 0 ||
              month.month >= currentMonth ||
              index === baselineIndex
                ? formatTickMonth(month.month)
                : ``}
            </div>
          ))}
        </div>

        {hoveredSlot && hoveredIndex !== null && (
          <div
            className="absolute z-30 bg-white shadow-xl rounded-xl p-4 border border-slate-200 pointer-events-none w-56"
            style={{
              top: 8,
              left: `${xForIndex(hoveredIndex)}%`,
              transform:
                hoveredIndex > chartMonths.length / 2
                  ? `translateX(-100%)`
                  : `translateX(0)`,
            }}
          >
            <span className="text-slate-400 text-xs font-medium block">
              {formatMonth(hoveredSlot.month)}
            </span>
            {hoveredMonth && (
              <>
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
                {hoveredProjection != null && (
                  <div className="mt-3 pt-2 border-t border-slate-100 text-xs text-slate-500">
                    <div className="flex items-center justify-between gap-3">
                      <span>Projected month-end</span>
                      <span className="font-medium text-slate-700">
                        {formatDollars(hoveredProjection)}
                      </span>
                    </div>
                    <span className="block mt-1 text-slate-400">At the current pace</span>
                  </div>
                )}
                <span className="text-xs text-slate-500 block mt-2">
                  {hoveredMonth.paidInvoices.toLocaleString()} paid invoice
                  {hoveredMonth.paidInvoices !== 1 && `s`}
                </span>
              </>
            )}
            {hoveredTrends.length > 0 && (
              <div className="mt-3 pt-2 border-t border-slate-100 text-xs text-slate-500 space-y-1">
                <span className="block text-slate-400">Trend forecasts</span>
                {hoveredTrends.map((trend) => (
                  <div
                    key={trend.lookbackMonths}
                    className={`flex items-center justify-between gap-3 ${trend.color}`}
                  >
                    <span>{trend.lookbackMonths}m avg</span>
                    <span className="font-medium">{formatDollars(trend.cents)}</span>
                  </div>
                ))}
                <span className="block text-slate-400">
                  Based on completed months only
                </span>
              </div>
            )}
            {!hoveredMonth && hoveredTrends.length === 0 && (
              <span className="block mt-2 text-xs text-slate-500">
                At least three completed months are needed for a trend forecast.
              </span>
            )}
          </div>
        )}
      </div>

      <div className="py-3 sm:py-4 px-4 sm:px-5 flex flex-col sm:flex-row sm:justify-between sm:items-center gap-3 border-t border-slate-200 bg-white rounded-b-xl">
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
              onClick={() => {
                setRange(value);
                setHoveredIndex(null);
              }}
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
