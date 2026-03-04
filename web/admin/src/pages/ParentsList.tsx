import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { PlanBadge, StatusBadge } from '../components/Badge';
import ErrorState from '../components/ErrorState';
import { UsersIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Pagination from '../components/Pagination';
import { formatDate } from '../lib/format';

const ParentsList: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const page = parseInt(searchParams.get(`page`) ?? `1`, 10);
  const emailParam = searchParams.get(`email`);

  const [data, setData] = useState<T.ParentsList.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchedEmail, setSearchedEmail] = useState<string | null>(null);

  useEffect(() => {
    if (!emailParam) {
      setSearchedEmail(null);
      return;
    }

    const searchByEmail = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.searchParentByEmail({ email: emailParam });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to search for parent`);
        setLoading(false);
        return;
      }

      if (result.value?.parentId) {
        navigate(`/parents/${result.value.parentId.toLowerCase()}`, { replace: true });
      } else {
        setSearchedEmail(emailParam);
        setLoading(false);
      }
    };

    searchByEmail();
  }, [emailParam, navigate]);

  useEffect(() => {
    if (emailParam) return;

    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.parentsList({ page, pageSize: 30 });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load parents`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [page, emailParam]);

  const goToPage = (newPage: number): void => {
    setSearchParams({ page: newPage.toString() });
  };

  if (loading) {
    return <LoadingState context="parents" />;
  }

  if (error) {
    return <ErrorState context="parents" error={error} />;
  }

  if (searchedEmail) {
    return (
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <UsersIcon className="w-5 h-5 text-white" />
          </div>
          <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
            Parents
          </h1>
        </div>
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-8 text-center">
          <p className="text-slate-600 mb-4">
            No parent found with email:{` `}
            <span className="font-mono text-slate-900">{searchedEmail}</span>
          </p>
          <button
            onClick={() => setSearchParams({})}
            className="px-4 py-2 bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white rounded-lg font-medium hover:opacity-90 transition-opacity"
          >
            View all parents
          </button>
        </div>
      </div>
    );
  }

  if (!data) {
    return null;
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <UsersIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-display font-semibold text-slate-900 tracking-tight">
              Parents
            </h1>
            <p className="text-sm text-slate-500">
              {data.totalCount.toLocaleString()} total accounts
            </p>
          </div>
        </div>
        <div className="self-center sm:self-auto">
          <Pagination
            currentPage={data.page}
            totalPages={data.totalPages}
            onPageChange={goToPage}
          />
        </div>
      </div>

      <div className="sm:hidden space-y-2">
        {data.parents.map((parent) => (
          <div
            key={parent.id}
            onClick={() => navigate(`/parents/${parent.id.toLowerCase()}`)}
            className="bg-white rounded-xl border border-slate-200/80 p-3 active:bg-slate-50 transition-colors cursor-pointer"
          >
            <div className="flex items-center justify-between gap-2 mb-2">
              <span className="text-brand-violet font-medium text-sm truncate">
                {parent.email}
              </span>
              <PlanBadge planCase={parent.planCase} status={parent.subscriptionStatus} />
            </div>
            <div className="flex items-center gap-2 mt-1">
              <span className="text-xs text-slate-400">
                {formatDate(parent.createdAt)}
              </span>
              <span
                className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium ${
                  parent.numChildren > 0
                    ? `bg-sky-50 text-sky-700 ring-1 ring-inset ring-sky-600/20`
                    : `bg-slate-50 text-slate-400 ring-1 ring-inset ring-slate-200`
                }`}
              >
                {parent.numChildren} kids
              </span>
              <span
                className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium ${
                  parent.iosDeviceCount > 0
                    ? `bg-teal-50 text-teal-700 ring-1 ring-inset ring-teal-600/20`
                    : `bg-slate-50 text-slate-400 ring-1 ring-inset ring-slate-200`
                }`}
              >
                {parent.iosDeviceCount} iOS
              </span>
              <span
                className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[11px] font-medium ${
                  parent.macDeviceCount > 0
                    ? `bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20`
                    : `bg-slate-50 text-slate-400 ring-1 ring-inset ring-slate-200`
                }`}
              >
                {parent.macDeviceCount} Mac
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="hidden sm:block bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-100">
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Email
              </th>
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Plan
              </th>
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Mac App
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Kids
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Mac
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                iOS
              </th>
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Created
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {data.parents.map((parent) => (
              <tr
                key={parent.id}
                onClick={() => navigate(`/parents/${parent.id.toLowerCase()}`)}
                className="hover:bg-slate-50/50 transition-colors group cursor-pointer"
              >
                <td className="px-5 py-4">
                  <span className="text-brand-violet group-hover:text-brand-fuchsia font-medium transition-colors text-sm">
                    {parent.email}
                  </span>
                </td>
                <td className="px-5 py-4">
                  <PlanBadge
                    planCase={parent.planCase}
                    status={parent.subscriptionStatus}
                  />
                </td>
                <td className="px-5 py-4">
                  <StatusBadge status={parent.macAppStatus} />
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${
                      parent.numChildren > 0
                        ? `bg-sky-100 text-sky-700`
                        : `bg-slate-100 text-slate-400`
                    }`}
                  >
                    {parent.numChildren}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${
                      parent.macDeviceCount > 0
                        ? `bg-amber-100 text-amber-700`
                        : `bg-slate-100 text-slate-400`
                    }`}
                  >
                    {parent.macDeviceCount}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${
                      parent.iosDeviceCount > 0
                        ? `bg-teal-100 text-teal-700`
                        : `bg-slate-100 text-slate-400`
                    }`}
                  >
                    {parent.iosDeviceCount}
                  </span>
                </td>
                <td className="px-5 py-4 text-sm text-slate-500 whitespace-nowrap">
                  {formatDate(parent.createdAt)}
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

export default ParentsList;
