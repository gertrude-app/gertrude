import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { IPadIcon, IPhoneIcon, MusicIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Pagination from '../components/Pagination';
import StatusPill from '../components/StatusPill';
import { formatDateTime } from '../lib/format';
import {
  MUSIC_INSTALL_STATUS_STYLES,
  UNKNOWN_MUSIC_INSTALL_STATUS_STYLE,
} from '../lib/musicInstallStatus';

const MusicInstallsList: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const page = parseInt(searchParams.get(`page`) ?? `1`, 10);

  const [data, setData] = useState<T.MusicInstallsList.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.musicInstallsList({ page, pageSize: 30 });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load music installs`);
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
    return <LoadingState context="music installs" gradient="violet" />;
  }

  if (error) {
    return <ErrorState context="music installs" error={error} />;
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-fuchsia-500 to-violet-600 flex items-center justify-center shadow-lg shadow-fuchsia-500/20">
            <MusicIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
              Music Installs
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
        <table className="w-full min-w-[680px]">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="text-left pl-5 pr-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">
                Install ID
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">
                Status
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-20">
                Albums
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-16">
                iOS
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-20">
                App
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
                  navigate(`/music/${install.deviceId.toLowerCase()}/detail`)
                }
                className="hover:bg-slate-50/50 transition-colors group cursor-pointer"
              >
                <td className="pl-5 pr-4 py-4">
                  <code className="text-fuchsia-600 group-hover:text-violet-600 font-mono text-sm transition-colors">
                    {install.deviceId.slice(0, 8).toLowerCase()}
                  </code>
                </td>
                <td className="px-4 py-4">
                  <StatusPill
                    status={install.status}
                    styles={MUSIC_INSTALL_STATUS_STYLES}
                    fallback={UNKNOWN_MUSIC_INSTALL_STATUS_STYLE}
                  />
                </td>
                <td className="px-4 py-4">
                  <span
                    className={`inline-flex items-center justify-center min-w-8 h-7 px-2 rounded-lg text-sm font-medium ${
                      install.albumCount > 0
                        ? `bg-fuchsia-100 text-fuchsia-700`
                        : `bg-slate-100 text-slate-500`
                    }`}
                  >
                    {install.albumCount}
                  </span>
                </td>
                <td className="px-4 py-4 text-sm text-slate-500">{install.iosVersion}</td>
                <td className="px-4 py-4 text-sm text-slate-500">
                  v{install.appVersion}
                </td>
                <td className="px-4 py-4 text-sm text-slate-700">
                  <span className="inline-flex items-center gap-1.5">
                    {install.deviceType.toLowerCase().includes(`ipad`) ? (
                      <IPadIcon className="w-4 h-4 text-violet-400" />
                    ) : (
                      <IPhoneIcon className="w-4 h-4 text-fuchsia-400" />
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

export default MusicInstallsList;
