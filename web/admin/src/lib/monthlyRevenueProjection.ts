type RevenueMonth = {
  month: string;
  centsCollected: number;
};

type RevenueGrowthForecast = {
  currentMonth: string;
  baseline: RevenueMonth | null;
  averageGrowthCents: number | null;
  months: { month: string; projectedCents: number | null }[];
};

const monthAtOffset = (now: Date, offset: number): string =>
  new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + offset, 1))
    .toISOString()
    .slice(0, 7);

export function monthlyRevenueGrowthForecast(
  months: RevenueMonth[],
  now: Date,
  lookbackMonths: 3 | 6 | 12 = 6,
): RevenueGrowthForecast {
  const history = Array.from({ length: lookbackMonths }, (_, index) =>
    months.find((month) => month.month === monthAtOffset(now, index - lookbackMonths)),
  );
  const firstMonth = history[0];
  const lastMonth = history.at(-1);
  const averageGrowthCents =
    firstMonth && lastMonth && history.every((month) => month !== undefined)
      ? (lastMonth.centsCollected - firstMonth.centsCollected) / (lookbackMonths - 1)
      : null;

  return {
    currentMonth: monthAtOffset(now, 0),
    baseline: averageGrowthCents !== null ? (lastMonth ?? null) : null,
    averageGrowthCents,
    months: Array.from({ length: 6 }, (_, index) => ({
      month: monthAtOffset(now, index),
      projectedCents:
        lastMonth && averageGrowthCents !== null
          ? Math.max(0, lastMonth.centsCollected + averageGrowthCents * (index + 1))
          : null,
    })),
  };
}

export function projectedMonthlyRevenue(
  month: string,
  centsCollected: number,
  now: Date,
): number | null {
  const year = now.getUTCFullYear();
  const monthIndex = now.getUTCMonth();
  const currentMonth = monthAtOffset(now, 0);
  if (month !== currentMonth) {
    return null;
  }

  const start = Date.UTC(year, monthIndex, 1);
  const end = Date.UTC(year, monthIndex + 1, 1);
  const elapsed = now.getTime() - start;
  return elapsed > 0 ? centsCollected * ((end - start) / elapsed) : centsCollected;
}
