import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { IPadIcon, IPhoneIcon, SmartphoneIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Pagination from '../components/Pagination';
import { formatDateTime } from '../lib/format';

const IOSDevicesList: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const page = parseInt(searchParams.get(`page`) ?? `1`, 10);

  const [data, setData] = useState<T.IOSDevicesList.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.iOSDevicesList({ page, pageSize: 30 });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load iOS devices`);
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
    return <LoadingState context="iOS devices" gradient="blue" />;
  }

  if (error) {
    return <ErrorState context="iOS devices" error={error} />;
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <SmartphoneIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
              iOS Devices
            </h1>
            <p className="text-sm text-slate-500">
              {data.totalCount.toLocaleString()} unique devices
            </p>
          </div>
        </div>
        <Pagination
          currentPage={data.page}
          totalPages={data.totalPages}
          onPageChange={goToPage}
        />
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="text-left pl-5 pr-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-28">
                Device ID
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-24">
                Status
              </th>
              <th className="text-left px-4 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-20">
                Events
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
            {data.devices.map((device) => (
              <tr
                key={device.vendorId}
                onClick={() => navigate(`/ios/${device.vendorId.toLowerCase()}/events`)}
                className="hover:bg-slate-50/50 transition-colors group cursor-pointer"
              >
                <td className="pl-5 pr-4 py-4">
                  <code className="text-sky-600 group-hover:text-blue-600 font-mono text-sm transition-colors">
                    {device.vendorId.slice(0, 8).toLowerCase()}
                  </code>
                </td>
                <td className="px-4 py-4">
                  {device.reachedOptOut ? (
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                      Success
                    </span>
                  ) : (
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                      Incomplete
                    </span>
                  )}
                </td>
                <td className="px-4 py-4">
                  <span
                    className={`inline-flex items-center justify-center w-8 h-7 rounded-lg text-sm font-medium ${
                      device.eventCount > 10
                        ? `bg-violet-100 text-violet-700`
                        : `bg-slate-100 text-slate-500`
                    }`}
                  >
                    {device.eventCount}
                  </span>
                </td>
                <td className="px-4 py-4 text-sm text-slate-500">{device.iosVersion}</td>
                <td className="px-4 py-4 text-sm text-slate-700">
                  <span className="inline-flex items-center gap-1.5">
                    {device.deviceType.toLowerCase().includes(`ipad`) ? (
                      <IPadIcon className="w-4 h-4 text-violet-400" />
                    ) : (
                      <IPhoneIcon className="w-4 h-4 text-sky-400" />
                    )}
                    {device.deviceType}
                  </span>
                </td>
                <td className="pl-4 pr-5 py-4 text-sm text-slate-500 text-right whitespace-nowrap">
                  {formatDateTime(device.firstLaunch)}
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

export default IOSDevicesList;
