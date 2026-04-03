import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { ArrowLeftIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';

type UnidentifiedApp = T.GetUnidentifiedApps.Output[`apps`][number];
type IdentifiedApp = T.GetIdentifiedAppsForAdmin.Output[number];

const THRESHOLD_OPTIONS = [
  { label: `100K`, value: 100_000 },
  { label: `50K`, value: 50_000 },
  { label: `10K`, value: 10_000 },
  { label: `1K`, value: 1_000 },
];

const AppNaming: React.FC = () => {
  const navigate = useNavigate();
  const [threshold, setThreshold] = useState(100_000);
  const [apps, setApps] = useState<UnidentifiedApp[]>([]);
  const [totalAboveThreshold, setTotalAboveThreshold] = useState(0);
  const [identifiedApps, setIdentifiedApps] = useState<IdentifiedApp[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const fetchApps = React.useCallback(async (thresh: number): Promise<void> => {
    setLoading(true);
    setLoadError(null);
    const [unidResult, idResult] = await Promise.all([
      client.getUnidentifiedApps({ threshold: thresh, limit: 0 }),
      client.getIdentifiedAppsForAdmin(undefined),
    ]);
    if (unidResult.isError || idResult.isError) {
      setLoadError(
        unidResult.error?.debugMessage ??
          idResult.error?.debugMessage ??
          `Failed to load apps`,
      );
      setLoading(false);
      return;
    }
    setApps(unidResult.value?.apps ?? []);
    setTotalAboveThreshold(unidResult.value?.totalAboveThreshold ?? 0);
    setIdentifiedApps(idResult.value ?? []);
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchApps(threshold);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleThresholdChange = (newThreshold: number): void => {
    setThreshold(newThreshold);
    fetchApps(newThreshold);
  };

  const handleSelectApp = (app: UnidentifiedApp): void => {
    navigate(`/app-naming/${encodeURIComponent(app.bundleId)}`, {
      state: { app, identifiedApps },
    });
  };

  if (loading) return <LoadingState context="app naming" />;
  if (loadError) return <ErrorState context="app naming" error={loadError} />;

  return (
    <div className="space-y-6 animate-fade-in pt-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-display font-semibold text-slate-900">
            App Naming
          </h1>
          <p className="text-slate-500 text-sm mt-1">
            {totalAboveThreshold} app{totalAboveThreshold !== 1 ? `s` : ``} above{` `}
            {threshold.toLocaleString()} requests
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Link
            to="/app-naming/scan"
            className="px-3 py-1.5 text-sm font-medium text-brand-violet hover:text-brand-fuchsia bg-brand-50 hover:bg-brand-100 rounded-lg transition-all"
          >
            iTunes Scan
          </Link>
          <span className="text-sm text-slate-500">Threshold:</span>
          <div className="flex rounded-lg border border-slate-200 overflow-hidden">
            {THRESHOLD_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => handleThresholdChange(opt.value)}
                className={`px-3 py-1.5 text-sm font-medium transition-colors ${
                  threshold === opt.value
                    ? `bg-brand-violet text-white`
                    : `bg-white text-slate-600 hover:bg-slate-50`
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="text-left px-4 py-3 font-medium text-slate-600">
                Bundle ID
              </th>
              <th className="text-left px-4 py-3 font-medium text-slate-600">
                Name Hints
              </th>
              <th className="text-right px-4 py-3 font-medium text-slate-600">
                Requests
              </th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {apps.map((app) => (
              <tr
                key={app.bundleId}
                onClick={() => handleSelectApp(app)}
                className="border-b border-slate-50 cursor-pointer transition-colors hover:bg-slate-50"
              >
                <td className="px-4 py-3 font-mono text-xs text-slate-700 max-w-xs truncate">
                  {app.bundleId}
                </td>
                <td className="px-4 py-3 text-slate-400 text-xs">
                  {app.localizedName ?? app.bundleName ?? `—`}
                </td>
                <td className="px-4 py-3 text-right font-mono text-slate-700">
                  {app.count.toLocaleString()}
                </td>
                <td className="px-4 py-3 text-right">
                  <button className="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-brand-violet hover:text-brand-fuchsia bg-brand-50 hover:bg-brand-100 rounded-lg transition-all group">
                    Name
                    <ArrowLeftIcon className="w-3 h-3 rotate-180 group-hover:translate-x-0.5 transition-transform" />
                  </button>
                </td>
              </tr>
            ))}
            {apps.length === 0 && (
              <tr>
                <td colSpan={4} className="px-4 py-12 text-center text-slate-400">
                  No apps above {threshold.toLocaleString()} requests
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AppNaming;
