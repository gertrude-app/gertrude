import React, { useState } from 'react';
import type { T } from '@shared/pairql/admin';
import { ChevronRightIcon, TrendingUpIcon } from './Icons';
import StatCard from './StatCard';

type Cohort = T.CohortAnalysis.Output[`cohorts`][number];

type RangeOption = `12m` | `24m` | `all`;

interface EnrichedCohort extends Cohort {
  trueCohort: number;
  noSurfaceCount: number;
  paidIntentNotPayingCount: number;
  paidIntentConv: number | null;
  monthsAgo: number;
  isCurrentMonth: boolean;
  isImmature: boolean;
}

const MATURITY_DAYS = 30;
const CHART_HEIGHT = 280;

const COLOR_PAYING = `#059669`;
const COLOR_INTENT = `#6ee7b7`;
const COLOR_FREE = `#3b82f6`;
const COLOR_NO_SURFACE = `#cbd5e1`;

const SEGMENTS = [
  { key: `paidIntentPayingCount`, label: `Paying`, color: COLOR_PAYING },
  {
    key: `paidIntentNotPayingCount`,
    label: `Paid-intent, not paying`,
    color: COLOR_INTENT,
  },
  { key: `freeIosCount`, label: `Free iOS`, color: COLOR_FREE },
  { key: `noSurfaceCount`, label: `Never activated`, color: COLOR_NO_SURFACE },
] as const;

const dateForMonth = (month: string): Date => new Date(`${month}-01T12:00:00`);

const formatMonth = (month: string): string =>
  dateForMonth(month).toLocaleDateString(`en-US`, { month: `short`, year: `2-digit` });

const formatTickMonth = (month: string): string =>
  dateForMonth(month).toLocaleDateString(`en-US`, { month: `short` });

const pctLabel = (n: number, d: number): string =>
  d > 0 ? `${Math.round((n / d) * 100)}%` : `—`;

const enrich = (cohorts: Cohort[], generatedAt: string): EnrichedCohort[] => {
  const gen = new Date(generatedAt);
  const genIndex = gen.getFullYear() * 12 + gen.getMonth();
  return cohorts.map((c) => {
    const parts = c.month.split(`-`);
    const year = Number(parts[0]);
    const month = Number(parts[1]);
    const cohortIndex = year * 12 + (month - 1);
    const monthsAgo = genIndex - cohortIndex;
    const monthEnd = new Date(year, month, 0, 23, 59, 59);
    const daysSinceMonthEnd = (gen.getTime() - monthEnd.getTime()) / 86_400_000;
    const noSurfaceCount = Math.max(
      0,
      c.verifiedSignups - c.paidIntentCount - c.freeIosCount,
    );
    return {
      ...c,
      trueCohort: c.verifiedSignups,
      noSurfaceCount,
      paidIntentNotPayingCount: Math.max(0, c.paidIntentCount - c.paidIntentPayingCount),
      paidIntentConv:
        c.paidIntentCount > 0 ? c.paidIntentPayingCount / c.paidIntentCount : null,
      monthsAgo,
      isCurrentMonth: monthsAgo === 0,
      isImmature: daysSinceMonthEnd < MATURITY_DAYS,
    };
  });
};

const sum = (cohorts: EnrichedCohort[], pick: (c: EnrichedCohort) => number): number =>
  cohorts.reduce((acc, c) => acc + pick(c), 0);

const CohortHealthSection: React.FC<{ data: T.CohortAnalysis.Output }> = ({ data }) => {
  const [range, setRange] = useState<RangeOption>(`12m`);

  const all = enrich(data.cohorts, data.generatedAt).sort((a, b) =>
    a.month.localeCompare(b.month),
  );
  const visible =
    range === `all` ? all : all.filter((c) => c.monthsAgo < (range === `12m` ? 12 : 24));

  const intent = sum(visible, (c) => c.paidIntentCount);
  const intentPaying = sum(visible, (c) => c.paidIntentPayingCount);
  const freeProtected = sum(visible, (c) => c.freeIosProtectedCount);
  const trueTotal = sum(visible, (c) => c.trueCohort);
  const surfaced = sum(visible, (c) => c.paidIntentCount + c.freeIosCount);

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100 flex flex-wrap justify-between items-center gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <TrendingUpIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Cohort Health
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Three engines: revenue · free-tier reach · activation
            </p>
          </div>
        </div>
        <div className="flex flex-wrap gap-1 items-center">
          {(
            [
              [`12m`, `12m`],
              [`24m`, `24m`],
              [`all`, `All`],
            ] as const
          ).map(([value, label]) => (
            <button
              key={value}
              onClick={() => setRange(value)}
              className={`px-2.5 sm:px-3 py-1.5 rounded-lg text-xs sm:text-sm font-medium transition-all ${
                range === value
                  ? `text-white bg-brand-violet shadow-md shadow-brand-violet/20`
                  : `text-slate-500 hover:text-slate-700 hover:bg-slate-100`
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
      <div className="p-4 sm:p-6 space-y-5">
        {visible.length === 0 ? (
          <p className="text-sm text-slate-500 py-8 text-center">
            No signup cohorts in this range.
          </p>
        ) : (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
              <StatCard
                label="Paid-intent → paying"
                value={`${pctLabel(intentPaying, intent)}`}
                subvalue={`${intentPaying} of ${intent} who tried Mac, iOS supervision, Podcasts, or Music`}
                highlight="green"
              />
              <StatCard
                label="Free iOS protected"
                value={freeProtected}
                subvalue="captured on the free tier"
                highlight="blue"
              />
              <StatCard
                label="Activated (any product)"
                value={`${pctLabel(surfaced, trueTotal)}`}
                subvalue={`${pctLabel(trueTotal - surfaced, trueTotal)} signed up but never activated`}
              />
            </div>

            <CohortCompositionChart cohorts={visible} />

            <HowToRead />
          </>
        )}
      </div>
    </section>
  );
};

const CohortCompositionChart: React.FC<{ cohorts: EnrichedCohort[] }> = ({ cohorts }) => {
  const [hovered, setHovered] = useState<number | null>(null);
  const n = cohorts.length;
  const maxTrue = Math.max(...cohorts.map((c) => c.trueCohort), 1);
  const labelStride = n <= 12 ? 1 : Math.ceil(n / 8);
  const hoveredCohort = hovered !== null ? cohorts[hovered] : null;

  return (
    <div className="bg-slate-50 rounded-xl border border-slate-100 p-4">
      <div className="mb-3 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-500">
        {SEGMENTS.map((s) => (
          <span key={s.key} className="inline-flex items-center gap-1.5">
            <span
              className="w-2.5 h-2.5 rounded-sm"
              style={{ backgroundColor: s.color }}
            />
            {s.label}
          </span>
        ))}
      </div>

      <div className="relative flex items-end gap-px" style={{ height: CHART_HEIGHT }}>
        {cohorts.map((c, index) => {
          const barHeight = Math.max((c.trueCohort / maxTrue) * CHART_HEIGHT, 2);
          return (
            <div
              key={c.month}
              className="flex-1 flex items-end cursor-pointer"
              onMouseEnter={() => setHovered(index)}
              onMouseLeave={() => setHovered(null)}
            >
              <div
                className={`w-full rounded-t-sm overflow-hidden flex flex-col-reverse transition-opacity ${
                  c.isImmature ? `opacity-50` : hovered === index ? `opacity-100` : ``
                }`}
                style={{ height: barHeight }}
              >
                {SEGMENTS.map((s) => {
                  const segHeight =
                    c.trueCohort > 0 ? (c[s.key] / c.trueCohort) * barHeight : 0;
                  return c[s.key] > 0 ? (
                    <div
                      key={s.key}
                      className="w-full"
                      style={{ height: segHeight, backgroundColor: s.color }}
                    />
                  ) : null;
                })}
              </div>
            </div>
          );
        })}

        {hoveredCohort && hovered !== null && (
          <div
            className="absolute z-30 bg-white shadow-xl rounded-xl p-3 border border-slate-200 pointer-events-none w-64"
            style={{
              top: 0,
              left: `${((hovered + 0.5) / n) * 100}%`,
              transform:
                hovered > n / 2
                  ? `translateX(-100%) translateX(-8px)`
                  : `translateX(8px)`,
            }}
          >
            <div className="flex items-center justify-between gap-2">
              <span className="text-slate-700 text-xs font-semibold">
                {formatMonth(hoveredCohort.month)}
              </span>
              <span className="text-xs text-slate-400">
                {hoveredCohort.trueCohort} signups
                {hoveredCohort.isImmature && (
                  <span className="ml-1.5 text-amber-600">
                    · {hoveredCohort.isCurrentMonth ? `partial` : `maturing`}
                  </span>
                )}
              </span>
            </div>
            <div className="mt-2 space-y-1 text-xs">
              <TooltipRow
                color={COLOR_PAYING}
                label="Paying"
                value={`${hoveredCohort.paidIntentPayingCount}`}
                note={pctLabel(
                  hoveredCohort.paidIntentPayingCount,
                  hoveredCohort.trueCohort,
                )}
              />
              <TooltipRow
                color={COLOR_INTENT}
                label="Paid-intent, not paying"
                value={`${hoveredCohort.paidIntentNotPayingCount}`}
                note={pctLabel(
                  hoveredCohort.paidIntentNotPayingCount,
                  hoveredCohort.trueCohort,
                )}
              />
              <TooltipRow
                color={COLOR_FREE}
                label="Free iOS"
                value={`${hoveredCohort.freeIosCount}`}
                note={pctLabel(hoveredCohort.freeIosCount, hoveredCohort.trueCohort)}
              />
              <TooltipRow
                color={COLOR_NO_SURFACE}
                label="Never activated"
                value={`${hoveredCohort.noSurfaceCount}`}
                note={pctLabel(hoveredCohort.noSurfaceCount, hoveredCohort.trueCohort)}
              />
            </div>
            {hoveredCohort.paidIntentConv !== null && (
              <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
                <span className="text-slate-500">Paid-intent → paying</span>
                <span className="font-medium text-emerald-600">
                  {Math.round(hoveredCohort.paidIntentConv * 100)}%
                </span>
              </div>
            )}
          </div>
        )}
      </div>

      <div className="mt-2 flex gap-px text-[10px] text-slate-400">
        {cohorts.map((c, index) => (
          <div key={c.month} className="flex-1 text-center truncate">
            {index % labelStride === 0 || index === n - 1 ? formatTickMonth(c.month) : ``}
          </div>
        ))}
      </div>
    </div>
  );
};

interface TooltipRowProps {
  color: string;
  label: string;
  value: string;
  note?: string;
}

const TooltipRow: React.FC<TooltipRowProps> = ({ color, label, value, note }) => (
  <div className="flex items-center justify-between gap-3 whitespace-nowrap">
    <span className="inline-flex items-center gap-1.5 text-slate-500">
      <span className="w-2 h-2 rounded-sm shrink-0" style={{ backgroundColor: color }} />
      {label}
    </span>
    <span className="font-medium text-slate-700">
      {value}
      {note && <span className="ml-1.5 text-slate-400 font-normal">{note}</span>}
    </span>
  </div>
);

const HowToRead: React.FC = () => {
  const [open, setOpen] = useState(false);
  return (
    <div className="border-t border-slate-100 pt-3">
      <button
        onClick={() => setOpen((o) => !o)}
        className="flex items-center gap-1.5 text-sm font-medium text-slate-500 hover:text-slate-700 transition-colors"
      >
        <ChevronRightIcon
          className={`w-4 h-4 transition-transform ${open ? `rotate-90` : ``}`}
        />
        How to read this
      </button>
      {open && (
        <div className="mt-3 space-y-3 text-sm leading-relaxed text-slate-500">
          <div>
            <p className="mb-1 font-medium text-slate-600">What the bars are</p>
            <p>
              Each bar is one month of verified signups, split by what they became:{` `}
              <span className="font-medium text-emerald-700">dark green</span> = paying
              (revenue),{` `}
              <span className="font-medium text-emerald-500">light green</span> = tried a
              paid product but hasn&apos;t paid (so the green&apos;s dark share is the
              conversion rate),{` `}
              <span className="font-medium text-blue-600">blue</span> = free iOS (mission
              reach, ~0% paid by design),{` `}
              <span className="font-medium text-slate-500">slate</span> = signed up, never
              used any product.
            </p>
          </div>
          <div>
            <p className="mb-1 font-medium text-slate-600">The question to bring</p>
            <p>
              Regarding revenue: cohort over cohort, are more people reaching paid value —
              and is it turning into paying customers? (Not &ldquo;are signups up.&rdquo;)
            </p>
          </div>
          <div>
            <p className="mb-1 font-medium text-slate-600">Watch, in this order</p>
            <ol className="list-decimal space-y-0.5 pl-4">
              <li>
                <span className="font-medium">Dark green, absolute size</span> — paying
                customers the cohort produced. Your revenue North Star; you want it
                growing.
              </li>
              <li>
                <span className="font-medium">The slate band</span> — roughly half of
                every cohort never activates. The biggest leak, and your highest-leverage
                focus. Think about how you can <b>shrink</b> this band.
              </li>
              <li>
                <span className="font-medium">The dark share of the green</span> —
                conversion (~55%). Healthy; confirm it isn&apos;t collapsing, don&apos;t
                obsess over it.
              </li>
              <li>
                <span className="font-medium">Only last</span> — total bar height and
                blue. For context and mission, not for feeling good about revenue.
              </li>
            </ol>
          </div>
          <div>
            <p className="mb-1 font-medium text-slate-600">Don&apos;t be deceived</p>
            <ul className="list-disc space-y-0.5 pl-4">
              <li>
                Blue is mission reach, not revenue — never add them. Booming blue with
                flat dark green means you&apos;re standing still with respect to revenue.
              </li>
              <li>
                Taller bars are more signups, not growth. They only count from a
                growth/revenue/sustainability perspective if they flow into green.
              </li>
              <li>
                A single month&apos;s conversion % is noise at these cohort sizes — trust
                the trailing rate in the card, not one bar.
              </li>
              <li>
                Recent cohorts are dimmed because their outcomes are still maturing (some
                paid-surface outcomes lag signup by weeks).
              </li>
            </ul>
          </div>
          <p className="font-medium text-slate-600">
            Bottom line: dark green up, slate band down — everything else is context.
          </p>
        </div>
      )}
    </div>
  );
};

export default CohortHealthSection;
