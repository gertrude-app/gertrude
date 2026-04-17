import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { ArrowLeftIcon, CheckIcon, ChevronRightIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Section from '../components/Section';
import StatCard from '../components/StatCard';

type Range = { label: string; hours: number };

const RANGES: Range[] = [
  { label: `24h`, hours: 24 },
  { label: `7d`, hours: 24 * 7 },
  { label: `30d`, hours: 24 * 30 },
];

const ERROR_FILTERS: { label: string; value: string | undefined }[] = [
  { label: `Unexpected`, value: `unexpected_error` },
  { label: `PqlError`, value: `pql_error` },
  { label: `Convertible`, value: `convertible_error` },
  { label: `Not Found`, value: `not_found` },
  { label: `All Errors`, value: undefined },
];

type SummaryRow = T.GetPairqlTelemetrySummary.Output[number];
type ErrorRow = T.GetRecentPairqlErrors.Output[number];

const DEFAULT_RANGE: Range = { label: `7d`, hours: 24 * 7 };

const THRESHOLDS = {
  p95SlowMs: 1000,
  p95WarnMs: 500,
  p95NoteMs: 200,
  minRequests: 10,
};

const TOOLTIPS = {
  p50: `Median: half of requests were faster than this, half were slower. Reflects the typical experience.`,
  p95: `95th percentile: 95% of requests finished in under this time. Reflects the slow tail (worst 1-in-20).`,
  p99: `99th percentile: 99% of requests finished in under this time. Reflects the rare worst case (worst 1-in-100).`,
  max: `Slowest single request in the time window.`,
  requests: `Total requests in the time window.`,
};

const PairqlTelemetry: React.FC = () => {
  const [range, setRange] = useState<Range>(DEFAULT_RANGE);
  const [errorFilter, setErrorFilter] = useState<string | undefined>(`unexpected_error`);
  const [summary, setSummary] = useState<SummaryRow[] | null>(null);
  const [errors, setErrors] = useState<ErrorRow[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hideLowVolume, setHideLowVolume] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);
      const [summaryResult, errorsResult] = await Promise.all([
        client.getPairqlTelemetrySummary({ sinceHours: range.hours }),
        client.getRecentPairqlErrors({
          sinceHours: range.hours,
          limit: 100,
          resultFilter: errorFilter,
        }),
      ]);
      if (cancelled) return;
      if (summaryResult.isError) {
        setError(summaryResult.error?.debugMessage ?? `Failed to load summary`);
        setLoading(false);
        return;
      }
      if (errorsResult.isError) {
        setError(errorsResult.error?.debugMessage ?? `Failed to load errors`);
        setLoading(false);
        return;
      }
      setSummary(summaryResult.value ?? []);
      setErrors(errorsResult.value ?? []);
      setLoading(false);
    };
    fetchData();
    return () => {
      cancelled = true;
    };
  }, [range, errorFilter]);

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-4">
        <Link
          to="/"
          className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 bg-slate-100 hover:bg-slate-200 rounded-lg transition-all group"
        >
          <ArrowLeftIcon className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
          <span>Back</span>
        </Link>
        <div>
          <h1 className="font-display font-semibold text-slate-900 text-2xl">
            PairQL Telemetry
          </h1>
          <p className="text-sm text-slate-500">Route performance and error visibility</p>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <span className="text-sm font-medium text-slate-600">Range:</span>
        {RANGES.map((r) => (
          <button
            key={r.label}
            onClick={() => setRange(r)}
            className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
              r.label === range.label
                ? `bg-slate-900 text-white`
                : `bg-slate-100 text-slate-600 hover:bg-slate-200`
            }`}
          >
            {r.label}
          </button>
        ))}
      </div>

      {loading ? (
        <LoadingState context="telemetry" />
      ) : error ? (
        <ErrorState context="telemetry" error={error} />
      ) : (
        <>
          <Highlights rows={summary ?? []} />

          {totalErrors(summary ?? []) === 0 ? (
            <div className="bg-emerald-50 border border-emerald-200 rounded-2xl px-5 py-4 flex items-center gap-3">
              <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-emerald-500 text-white">
                <CheckIcon className="w-4 h-4" />
              </span>
              <div>
                <div className="font-medium text-emerald-900">
                  No errors in the last {range.label}
                </div>
                <div className="text-sm text-emerald-700">
                  Every PairQL request returned a successful response.
                </div>
              </div>
            </div>
          ) : (
            <Section title={`Recent Errors (${range.label})`}>
              <div className="flex flex-wrap items-center gap-2 mb-4">
                <span className="text-sm font-medium text-slate-600">Filter:</span>
                {ERROR_FILTERS.map((f) => (
                  <button
                    key={f.label}
                    onClick={() => setErrorFilter(f.value)}
                    className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-all ${
                      f.value === errorFilter
                        ? `bg-red-600 text-white`
                        : `bg-slate-100 text-slate-600 hover:bg-slate-200`
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>
              <ErrorsTable
                rows={errors ?? []}
                emptyHint={
                  errorFilter
                    ? `No ${errorFilter} rows in this range — try “All Errors”.`
                    : `No errors in this range.`
                }
              />
            </Section>
          )}

          <Section title={`Operations Summary (${range.label}, sorted by p95)`}>
            <div className="flex items-center gap-3 mb-4">
              <label className="flex items-center gap-2 text-sm text-slate-600 cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={hideLowVolume}
                  onChange={(e) => setHideLowVolume(e.target.checked)}
                  className="rounded border-slate-300 text-slate-900 focus:ring-slate-900"
                />
                Hide low-volume ops (&lt; {THRESHOLDS.minRequests} requests)
              </label>
              {hideLowVolume && summary && (
                <span className="text-xs text-slate-400">
                  {hiddenCount(summary)} hidden
                </span>
              )}
            </div>
            <SummaryTable
              rows={(summary ?? []).filter((r) =>
                hideLowVolume ? r.requestCount >= THRESHOLDS.minRequests : true,
              )}
            />
          </Section>
        </>
      )}
    </div>
  );
};

const Highlights: React.FC<{ rows: SummaryRow[] }> = ({ rows }) => {
  const slowOps = rows.filter(
    (r) => r.p95Ms >= THRESHOLDS.p95SlowMs && r.requestCount >= THRESHOLDS.minRequests,
  ).length;
  const unexpectedErrors = rows.reduce((sum, r) => sum + r.unexpectedErrorCount, 0);
  const total = totalErrors(rows);
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
      <StatCard
        label={`Ops with p95 ≥ ${THRESHOLDS.p95SlowMs}ms`}
        value={slowOps}
        subvalue={`min ${THRESHOLDS.minRequests} requests`}
        highlight={slowOps > 0 ? `red` : undefined}
      />
      <StatCard
        label="Unexpected errors"
        value={unexpectedErrors}
        subvalue="silent-swallow signal"
        highlight={unexpectedErrors > 0 ? `red` : undefined}
      />
      <StatCard
        label="Total errors (all kinds)"
        value={total}
        highlight={total > 0 ? `amber` : undefined}
      />
    </div>
  );
};

function hiddenCount(rows: SummaryRow[]): string {
  const n = rows.filter((r) => r.requestCount < THRESHOLDS.minRequests).length;
  return n === 1 ? `1 op` : `${n} ops`;
}

function totalErrors(rows: SummaryRow[]): number {
  return rows.reduce(
    (sum, r) =>
      sum +
      r.pqlErrorCount +
      r.convertibleErrorCount +
      r.unexpectedErrorCount +
      r.notFoundCount,
    0,
  );
}

const SummaryTable: React.FC<{ rows: SummaryRow[] }> = ({ rows }) => {
  if (rows.length === 0) {
    return <p className="text-sm text-slate-500">No data in this range.</p>;
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
            <th className="py-2 pr-3">Domain</th>
            <th className="py-2 pr-3">Operation</th>
            <th className="py-2 px-3 text-right">
              <HeaderHint label="Requests" hint={TOOLTIPS.requests} />
            </th>
            <th className="py-2 px-3 text-right">
              <HeaderHint label="p50" hint={TOOLTIPS.p50} />
            </th>
            <th className="py-2 px-3 text-right">
              <HeaderHint label="p95" hint={TOOLTIPS.p95} />
            </th>
            <th className="py-2 px-3 text-right">
              <HeaderHint label="p99" hint={TOOLTIPS.p99} />
            </th>
            <th className="py-2 px-3 text-right">
              <HeaderHint label="Max" hint={TOOLTIPS.max} />
            </th>
            <th className="py-2 px-3 text-right">OK</th>
            <th className="py-2 px-3 text-right">PqlErr</th>
            <th className="py-2 px-3 text-right">ConvErr</th>
            <th className="py-2 px-3 text-right text-red-600">Unexpected</th>
            <th className="py-2 pl-3 text-right">NotFound</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => {
            const hasUnexpected = r.unexpectedErrorCount > 0;
            return (
              <tr
                key={`${r.domain}-${r.operation}`}
                className={`border-b border-slate-100 ${
                  hasUnexpected ? `bg-red-50` : ``
                }`}
              >
                <td className="py-2 pr-3 text-slate-500">{r.domain}</td>
                <td className="py-2 pr-3 font-medium text-slate-900">{r.operation}</td>
                <td className="py-2 px-3 text-right text-slate-700">
                  {r.requestCount.toLocaleString()}
                </td>
                <td className="py-2 px-3 text-right text-slate-700">{r.p50Ms}</td>
                <td className={`py-2 px-3 text-right font-medium ${p95Color(r.p95Ms)}`}>
                  {r.p95Ms}
                </td>
                <td className="py-2 px-3 text-right text-slate-700">{r.p99Ms}</td>
                <td className="py-2 px-3 text-right text-slate-500">{r.maxMs}</td>
                <td className="py-2 px-3 text-right text-slate-500">
                  {r.okCount.toLocaleString()}
                </td>
                <td
                  className={`py-2 px-3 text-right ${
                    r.pqlErrorCount > 0 ? `text-amber-600` : `text-slate-300`
                  }`}
                >
                  {r.pqlErrorCount}
                </td>
                <td
                  className={`py-2 px-3 text-right ${
                    r.convertibleErrorCount > 0 ? `text-amber-600` : `text-slate-300`
                  }`}
                >
                  {r.convertibleErrorCount}
                </td>
                <td
                  className={`py-2 px-3 text-right font-semibold ${
                    hasUnexpected ? `text-red-600` : `text-slate-300`
                  }`}
                >
                  {r.unexpectedErrorCount}
                </td>
                <td
                  className={`py-2 pl-3 text-right ${
                    r.notFoundCount > 0 ? `text-slate-700` : `text-slate-300`
                  }`}
                >
                  {r.notFoundCount}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

const ErrorsTable: React.FC<{ rows: ErrorRow[]; emptyHint: string }> = ({
  rows,
  emptyHint,
}) => {
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const expandableCount = rows.filter((r) => r.errorMessage).length;
  const allExpanded = expandableCount > 0 && expanded.size === expandableCount;

  const toggle = (id: string): void => {
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAll = (): void => {
    if (allExpanded) setExpanded(new Set());
    else setExpanded(new Set(rows.filter((r) => r.errorMessage).map((r) => r.id)));
  };

  if (rows.length === 0) {
    return <p className="text-sm text-slate-500">{emptyHint}</p>;
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
            <th className="py-2 pr-3 w-6">
              {expandableCount > 0 && (
                <button
                  onClick={toggleAll}
                  className="text-slate-400 hover:text-slate-700 transition-colors"
                  title={allExpanded ? `Collapse all` : `Expand all`}
                  aria-label={allExpanded ? `Collapse all` : `Expand all`}
                >
                  <ChevronRightIcon
                    className={`w-4 h-4 transition-transform ${allExpanded ? `rotate-90` : ``}`}
                  />
                </button>
              )}
            </th>
            <th className="py-2 pr-3">When</th>
            <th className="py-2 px-3">Result</th>
            <th className="py-2 px-3">Domain</th>
            <th className="py-2 px-3">Operation</th>
            <th className="py-2 px-3">Error Type</th>
            <th className="py-2 px-3">Error ID</th>
            <th className="py-2 px-3 text-right">Duration</th>
            <th className="py-2 pl-3">Request ID</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => {
            const isOpen = expanded.has(r.id);
            const canExpand = !!r.errorMessage;
            return (
              <React.Fragment key={r.id}>
                <tr
                  onClick={canExpand ? () => toggle(r.id) : undefined}
                  className={`${
                    isOpen ? `border-t border-slate-100` : `border-b border-slate-100`
                  } ${canExpand ? `cursor-pointer hover:bg-slate-50` : ``}`}
                >
                  <td className="py-2 pr-3 w-6 text-slate-400">
                    {canExpand && (
                      <ChevronRightIcon
                        className={`w-4 h-4 transition-transform ${isOpen ? `rotate-90` : ``}`}
                      />
                    )}
                  </td>
                  <td className="py-2 pr-3 whitespace-nowrap text-slate-600">
                    {formatWhen(r.createdAt)}
                  </td>
                  <td className="py-2 px-3">
                    <span className={`text-xs font-medium ${resultColor(r.result)}`}>
                      {r.result}
                    </span>
                  </td>
                  <td className="py-2 px-3 text-slate-500">{r.domain}</td>
                  <td className="py-2 px-3 font-medium text-slate-900">{r.operation}</td>
                  <td className="py-2 px-3 text-slate-700">{r.errorType ?? `—`}</td>
                  <td className="py-2 px-3 font-mono text-xs text-slate-500">
                    {r.errorId ?? `—`}
                  </td>
                  <td className="py-2 px-3 text-right text-slate-500">
                    {r.durationMs}ms
                  </td>
                  <td className="py-2 pl-3 font-mono text-xs text-slate-400">
                    {r.requestId}
                  </td>
                </tr>
                {canExpand && isOpen && (
                  <tr className="border-b border-slate-100 bg-slate-50/60">
                    <td className="pb-3 pr-3" />
                    <td
                      colSpan={8}
                      className="pb-3 pl-3 pr-3 font-mono text-xs text-slate-700 whitespace-pre-wrap break-words leading-snug"
                    >
                      {r.errorMessage}
                    </td>
                  </tr>
                )}
              </React.Fragment>
            );
          })}
        </tbody>
      </table>
    </div>
  );
};

const HeaderHint: React.FC<{ label: string; hint: string }> = ({ label, hint }) => (
  <span
    title={hint}
    className="inline-flex items-center gap-1 cursor-help border-b border-dotted border-slate-300"
  >
    {label}
  </span>
);

function p95Color(ms: number): string {
  if (ms >= THRESHOLDS.p95SlowMs) return `text-red-600`;
  if (ms >= THRESHOLDS.p95WarnMs) return `text-amber-600`;
  if (ms >= THRESHOLDS.p95NoteMs) return `text-yellow-600`;
  return `text-slate-700`;
}

function resultColor(result: string): string {
  switch (result) {
    case `unexpected_error`:
      return `text-red-600`;
    case `pql_error`:
    case `convertible_error`:
      return `text-amber-600`;
    case `not_found`:
      return `text-slate-500`;
    default:
      return `text-slate-700`;
  }
}

function formatWhen(iso: string): string {
  const d = new Date(iso);
  const now = Date.now();
  const diffMs = now - d.getTime();
  const mins = Math.floor(diffMs / 60000);
  if (mins < 1) return `just now`;
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;
  return d.toLocaleDateString();
}

export default PairqlTelemetry;
