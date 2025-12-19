import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';

interface IconProps {
  className?: string;
}

const UsersIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="1.5"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
    <circle cx="9" cy="7" r="4" />
    <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
    <path d="M16 3.13a4 4 0 0 1 0 7.75" />
  </svg>
);

const ChevronLeftIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="m15 18-6-6 6-6" />
  </svg>
);

const ChevronRightIcon: React.FC<IconProps> = ({ className = `` }) => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    className={className}
  >
    <path d="m9 18 6-6-6-6" />
  </svg>
);

const LoadingSpinner: React.FC<IconProps> = ({ className = `` }) => (
  <svg className={`animate-spin ${className}`} viewBox="0 0 24 24" fill="none">
    <circle
      className="opacity-25"
      cx="12"
      cy="12"
      r="10"
      stroke="currentColor"
      strokeWidth="3"
    />
    <path
      className="opacity-75"
      fill="currentColor"
      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
    />
  </svg>
);

const ParentsList: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const page = parseInt(searchParams.get(`page`) ?? `1`, 10);

  const [data, setData] = useState<T.ParentsList.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
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
  }, [page]);

  const goToPage = (newPage: number): void => {
    setSearchParams({ page: newPage.toString() });
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-24">
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-4 shadow-lg shadow-brand-violet/20">
          <LoadingSpinner className="w-6 h-6 text-white" />
        </div>
        <p className="text-slate-500 font-medium">Loading parents...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-100 rounded-2xl p-6">
        <div className="flex items-start gap-4">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-red-400 to-red-500 flex items-center justify-center flex-shrink-0">
            <svg
              className="w-5 h-5 text-white"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
            >
              <circle cx="12" cy="12" r="10" />
              <path d="M12 8v4M12 16h.01" />
            </svg>
          </div>
          <div>
            <h3 className="font-display font-semibold text-red-900">
              Failed to load parents
            </h3>
            <p className="mt-1 text-red-700">{error}</p>
          </div>
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
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${parent.numChildren > 0 ? `bg-sky-100 text-sky-700` : `bg-slate-100 text-slate-400`}`}
                  >
                    {parent.numChildren}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${parent.numKeychains > 0 ? `bg-violet-100 text-violet-700` : `bg-slate-100 text-slate-400`}`}
                  >
                    {parent.numKeychains}
                  </span>
                </td>
                <td className="px-5 py-4 text-center">
                  <span
                    className={`inline-flex items-center justify-center w-7 h-7 rounded-lg text-sm font-medium ${parent.numNotifications > 0 ? `bg-emerald-100 text-emerald-700` : `bg-slate-100 text-slate-400`}`}
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

interface BadgeProps {
  status: string;
}

const StatusBadge: React.FC<BadgeProps> = ({ status }) => {
  const styles: Record<string, string> = {
    active: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
    onboarded: `bg-sky-50 text-sky-700 ring-sky-600/20`,
    no_action: `bg-slate-50 text-slate-400 ring-slate-300/20 opacity-60`,
    unknown: `bg-slate-50 text-slate-600 ring-slate-500/20`,
  };

  const labels: Record<string, string> = {
    active: `Active`,
    onboarded: `Onboarded`,
    no_action: `No Action`,
    unknown: `Unknown`,
  };

  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium ring-1 ring-inset ${styles[status] ?? styles.unknown}`}
    >
      {labels[status] ?? status}
    </span>
  );
};

const SubscriptionBadge: React.FC<BadgeProps> = ({ status }) => {
  const styles: Record<string, string> = {
    paid: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
    trialing: `bg-sky-50 text-sky-700 ring-sky-600/20`,
    trialExpiringSoon: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    overdue: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    unpaid: `bg-red-50 text-red-700 ring-red-600/20`,
    pendingEmailVerification: `bg-slate-50 text-slate-600 ring-slate-500/20`,
    complimentary: `bg-violet-50 text-violet-700 ring-violet-600/20`,
  };

  const labels: Record<string, string> = {
    paid: `Paid`,
    trialing: `Trial`,
    trialExpiringSoon: `Trial Expiring Soon`,
    overdue: `Overdue`,
    unpaid: `Unpaid`,
    pendingEmailVerification: `Pending`,
    complimentary: `Complimentary`,
  };

  return (
    <span
      className={`inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium ring-1 ring-inset ${styles[status] ?? `bg-slate-50 text-slate-600 ring-slate-500/20`}`}
    >
      {labels[status] ?? status}
    </span>
  );
};

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
}

const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  onPageChange,
}) => (
  <div className="flex items-center gap-1">
    <button
      onClick={() => onPageChange(currentPage - 1)}
      disabled={currentPage <= 1}
      className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-transparent"
    >
      <ChevronLeftIcon className="w-5 h-5" />
    </button>
    <div className="flex items-center gap-1 px-2">
      {getPageNumbers(currentPage, totalPages).map((pageNum, idx) =>
        pageNum === `...` ? (
          <span key={`ellipsis-${idx}`} className="px-2 text-slate-400">
            ...
          </span>
        ) : (
          <button
            key={pageNum}
            onClick={() => onPageChange(pageNum as number)}
            className={`min-w-[36px] h-9 px-3 rounded-lg text-sm font-medium transition-all ${
              pageNum === currentPage
                ? `bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white shadow-sm`
                : `text-slate-600 hover:bg-slate-100`
            }`}
          >
            {pageNum}
          </button>
        ),
      )}
    </div>
    <button
      onClick={() => onPageChange(currentPage + 1)}
      disabled={currentPage >= totalPages}
      className="p-2 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-all disabled:opacity-40 disabled:cursor-not-allowed disabled:hover:bg-transparent"
    >
      <ChevronRightIcon className="w-5 h-5" />
    </button>
  </div>
);

function getPageNumbers(current: number, total: number): (number | string)[] {
  if (total <= 7) {
    return Array.from({ length: total }, (_, i) => i + 1);
  }

  if (current <= 3) {
    return [1, 2, 3, 4, 5, `...`, total];
  }

  if (current >= total - 2) {
    return [1, `...`, total - 4, total - 3, total - 2, total - 1, total];
  }

  return [1, `...`, current - 1, current, current + 1, `...`, total];
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString(`en-US`, {
    year: `numeric`,
    month: `short`,
    day: `numeric`,
  });
}

export default ParentsList;
