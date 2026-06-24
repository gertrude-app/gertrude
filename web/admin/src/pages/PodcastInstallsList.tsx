import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { IPadIcon, IPhoneIcon, MicIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Pagination from '../components/Pagination';
import StatusPill from '../components/StatusPill';
import { formatDateTime } from '../lib/format';

const PodcastInstallsList: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const page = parseInt(searchParams.get(`page`) ?? `1`, 10);

  const [data, setData] = useState<T.PodcastInstallsList.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.podcastInstallsList({ page, pageSize: 30 });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load podcast installs`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [page]);

  const goToPage = (newPage: number): void => {
    setSearchParams({ page: newPage.toString() });
  };

  if (loading) {
    return <LoadingState context="podcast installs" gradient="green" />;
  }

  if (error) {
    return <ErrorState context="podcast installs" error={error} />;
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
            <MicIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
              Podcast Installs
            </h1>
            <p className="text-sm text-slate-500">
              {data.totalCount.toLocaleString()} unique installs
            </p>
          </div>
        </div>
        <Pagination
          currentPage={data.page}
          totalPages={data.totalPages}
          onPageChange={goToPage}
        />
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-x-auto">
        <table className="w-full min-w-[600px]">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="text-left pl-5 pr-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">
                Install ID
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">
                Status
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-16">
                Feeds
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-16">
                iOS
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Device
              </th>
              <th className="text-right pl-4 pr-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-40">
                First Launch
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {data.installs.map((install) => (
              <tr
                key={install.deviceId}
                onClick={() =>
                  navigate(`/podcasts/${install.deviceId.toLowerCase()}/detail`)
                }
                className="hover:bg-slate-50/50 transition-colors group cursor-pointer"
              >
                <td className="pl-5 pr-4 py-4">
                  <code className="text-emerald-600 group-hover:text-green-600 font-mono text-sm transition-colors">
                    {install.deviceId.slice(0, 8).toLowerCase()}
                  </code>
                </td>
                <td className="px-4 py-4">
                  <StatusPill
                    status={install.status}
                    styles={STATUS_STYLES}
                    fallback={{
                      label: `Trial`,
                      className: `bg-slate-100 text-slate-500`,
                    }}
                  />
                </td>
                <td className="px-4 py-4">
                  <span
                    className={`inline-flex items-center justify-center w-8 h-7 rounded-lg text-sm font-medium ${
                      install.feedCount > 0
                        ? `bg-emerald-100 text-emerald-700`
                        : `bg-slate-100 text-slate-500`
                    }`}
                  >
                    {install.feedCount}
                  </span>
                </td>
                <td className="px-4 py-4 text-sm text-slate-500">{install.iosVersion}</td>
                <td className="px-4 py-4 text-sm text-slate-700">
                  <span className="inline-flex items-center gap-1.5">
                    {install.deviceType.toLowerCase().includes(`ipad`) ? (
                      <IPadIcon className="w-4 h-4 text-violet-400" />
                    ) : (
                      <IPhoneIcon className="w-4 h-4 text-emerald-400" />
                    )}
                    {install.modelName}
                  </span>
                </td>
                <td className="pl-4 pr-5 py-4 text-sm text-slate-500 text-right whitespace-nowrap">
                  {formatDateTime(install.firstLaunch)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex justify-center">
        <Pagination
          currentPage={data.page}
          totalPages={data.totalPages}
          onPageChange={goToPage}
        />
      </div>
    </div>
  );
};

const STATUS_STYLES: Record<string, { label: string; className: string }> = {
  paid: { label: `Paid`, className: `bg-green-100 text-green-700` },
  complimentary: { label: `Comp`, className: `bg-rose-100 text-rose-700` },
  connected: { label: `Connected`, className: `bg-violet-100 text-violet-700` },
  iap: { label: `IAP`, className: `bg-amber-100 text-amber-700` },
  expired: { label: `Expired`, className: `bg-slate-100 text-slate-500` },
};

export default PodcastInstallsList;
