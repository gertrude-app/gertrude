import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { StatusBadge, SubscriptionBadge } from '../components/Badge';
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
      <div className="flex justify-between items-center">
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
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Email
              </th>
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Status
              </th>
              <th className="text-left px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Subscription
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Kids
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Keys
              </th>
              <th className="text-center px-5 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                Notifs
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
                  <span className="text-brand-violet group-hover:text-brand-fuchsia font-medium transition-colors">
                    {parent.email}
                  </span>
                </td>
                <td className="px-5 py-4">
                  <StatusBadge status={parent.status} />
                </td>
                <td className="px-5 py-4">
                  <SubscriptionBadge status={parent.subscriptionStatus} />
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
                      parent.numKeychains > 0
                        ? `bg-violet-100 text-violet-700`
                        : `bg-slate-100 text-slate-400`
                    }`}
                  >
                    {parent.numKeychains}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${
                      parent.numNotifications > 0
                        ? `bg-emerald-100 text-emerald-700`
                        : `bg-slate-100 text-slate-400`
                    }`}
                  >
                    {parent.numNotifications}
                  </span>
                </td>
                <td className="px-5 py-4 text-sm text-slate-500">
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
