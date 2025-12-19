import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';

interface IconProps {
  className?: string;
}

const CopyIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <rect width="14" height="14" x="8" y="8" rx="2" ry="2" />
    <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
  </svg>
);

const CheckIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="M20 6 9 17l-5-5" />
  </svg>
);

interface CopyButtonProps {
  text: string;
}

const CopyButton: React.FC<CopyButtonProps> = ({ text }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async (): Promise<void> => {
    await navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  };

  return (
    <button
      onClick={handleCopy}
      className="p-1 rounded hover:bg-slate-100 text-slate-400 hover:text-slate-600 transition-colors"
      title="Copy to clipboard"
    >
      {copied ? (
        <CheckIcon className="w-4 h-4 text-emerald-500" />
      ) : (
        <CopyIcon className="w-4 h-4" />
      )}
    </button>
  );
};

const LinkIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71" />
    <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71" />
  </svg>
);

interface CopyLinkButtonProps {
  childId: string;
}

const CopyLinkButton: React.FC<CopyLinkButtonProps> = ({ childId }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async (): Promise<void> => {
    const url = `https://parents.gertrude.app/children/${childId.toLowerCase()}`;
    await navigator.clipboard.writeText(url);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button
      onClick={handleCopy}
      className="inline-flex items-center gap-1.5 px-2 py-1 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition-colors text-xs"
      title="Copy child settings link"
    >
      {copied ? (
        <>
          <CheckIcon className="w-3.5 h-3.5 text-emerald-500" />
          <span className="text-emerald-600 font-medium">Child settings link copied</span>
        </>
      ) : (
        <LinkIcon className="w-3.5 h-3.5" />
      )}
    </button>
  );
};

const ArrowLeftIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="m12 19-7-7 7-7" />
    <path d="M19 12H5" />
  </svg>
);

const UserIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <circle cx="12" cy="8" r="5" />
    <path d="M20 21a8 8 0 0 0-16 0" />
  </svg>
);

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

const KeyIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <circle cx="7.5" cy="15.5" r="5.5" />
    <path d="m21 2-9.6 9.6" />
    <path d="m15.5 7.5 3 3L22 7l-3-3" />
  </svg>
);

const BellIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" />
    <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />
  </svg>
);

const MonitorIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <rect width="20" height="14" x="2" y="3" rx="2" />
    <line x1="8" x2="16" y1="21" y2="21" />
    <line x1="12" x2="12" y1="17" y2="21" />
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

const ParentDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const [data, setData] = useState<T.ParentDetail.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;

    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.parentDetail({ id });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load parent`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [id]);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-24">
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-4 shadow-lg shadow-brand-violet/20">
          <LoadingSpinner className="w-6 h-6 text-white" />
        </div>
        <p className="text-slate-500 font-medium">Loading parent details...</p>
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
              Failed to load parent
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
      <div className="flex items-center gap-4">
        <Link
          to="/parents"
          className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-all group"
        >
          <ArrowLeftIcon className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
          <span>Back to Parents</span>
        </Link>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-start">
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
              <UserIcon className="w-6 h-6 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-1">
                <h1 className="text-xl font-display font-semibold text-slate-900 tracking-tight">
                  {data.email}
                </h1>
                <CopyButton text={data.email} />
              </div>
              <div className="flex items-center gap-1 mt-0.5">
                <p className="text-sm text-slate-500 font-mono">
                  {data.id.toLowerCase()}
                </p>
                <CopyButton text={data.id.toLowerCase()} />
              </div>
            </div>
          </div>
          <SubscriptionBadge status={data.subscriptionStatus} />
        </div>

        <div className="p-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <InfoCard label="Subscription" value={data.subscriptionStatus} />
            <InfoCard
              label="Monthly Price"
              value={`$${(data.monthlyPriceInCents / 100).toFixed(2)}`}
              highlight
            />
            <InfoCard label="Children" value={data.children.length.toString()} />
            <InfoCard label="Created" value={formatDate(data.createdAt)} />
          </div>

          {data.subscriptionId && (
            <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
              <span className="text-sm text-slate-500">Stripe ID: </span>
              <a
                href={`https://dashboard.stripe.com/acct_1L8TXdGKRdhETuKA/subscriptions/${data.subscriptionId}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm font-mono text-brand-violet hover:text-brand-fuchsia transition-colors"
              >
                {data.subscriptionId}
              </a>
            </div>
          )}
        </div>
      </div>

      <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-6 py-5 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-sky-100 flex items-center justify-center">
              <UsersIcon className="w-5 h-5 text-sky-600" />
            </div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Children
              <span className="ml-2 text-sm font-normal text-slate-500">
                ({data.children.length})
              </span>
            </h2>
          </div>
        </div>
        <div className="p-6">
          {data.children.length === 0 ? (
            <p className="text-slate-500 text-center py-4">No children configured</p>
          ) : (
            <div className="space-y-4">
              {data.children.map((child) => (
                <div
                  key={child.id}
                  className="border border-slate-200 rounded-xl p-5 hover:border-slate-300 transition-colors"
                >
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-sky-100 flex items-center justify-center">
                        <UserIcon className="w-[18px] h-[18px] text-sky-600" />
                      </div>
                      <h3 className="font-display font-semibold text-slate-900 text-xl">
                        {child.name}
                      </h3>
                      <CopyLinkButton childId={child.id} />
                    </div>
                    <div className="flex gap-2">
                      {child.keyloggingEnabled && (
                        <span className="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20">
                          Keylogging
                        </span>
                      )}
                      {child.screenshotsEnabled && (
                        <span className="inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium bg-sky-50 text-sky-700 ring-1 ring-inset ring-sky-600/20">
                          Screenshots
                        </span>
                      )}
                    </div>
                  </div>

                  {child.installations.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-3">
                        <MonitorIcon className="w-4 h-4 text-slate-400" />
                        <h4 className="text-sm font-medium text-slate-700">
                          Computer users ({child.installations.length})
                        </h4>
                      </div>
                      <div className="grid gap-2">
                        {child.installations.map((install) => (
                          <div
                            key={install.id}
                            className="bg-slate-50 rounded-xl p-4 border border-slate-100 flex gap-4"
                          >
                            <div className="flex-shrink-0 w-20 h-20 bg-white rounded-lg border border-slate-200 flex items-center justify-center p-2">
                              <img
                                src={`https://parents.gertrude.app/macs/${install.modelIdentifier}.png`}
                                alt={install.modelTitle}
                                className="max-w-full max-h-full object-contain"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = `none`;
                                }}
                              />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex justify-between items-start gap-2">
                                <span className="font-medium text-slate-900">
                                  {install.modelTitle}
                                </span>
                                <span className="text-xs text-slate-400 flex-shrink-0">
                                  {formatDate(install.createdAt)}
                                </span>
                              </div>
                              <p className="text-xs text-slate-400 font-mono mt-0.5">
                                {install.modelIdentifier}
                              </p>
                              <div className="text-sm text-slate-600 mt-2 flex flex-wrap gap-x-4 gap-y-1">
                                <span>App v{install.appVersion}</span>
                                {install.filterVersion && (
                                  <span>Filter v{install.filterVersion}</span>
                                )}
                                {install.osVersion && (
                                  <span>macOS {install.osVersion}</span>
                                )}
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-6 py-5 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-violet-100 flex items-center justify-center">
              <KeyIcon className="w-5 h-5 text-violet-600" />
            </div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Keychains
              <span className="ml-2 text-sm font-normal text-slate-500">
                ({data.keychains.length})
              </span>
            </h2>
          </div>
        </div>
        <div className="p-6">
          {data.keychains.length === 0 ? (
            <p className="text-slate-500 text-center py-4">No keychains configured</p>
          ) : (
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {data.keychains.map((keychain) => (
                <div
                  key={keychain.id}
                  className="border border-slate-200 rounded-xl p-4 hover:border-slate-300 transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-slate-900">{keychain.name}</span>
                    {keychain.isPublic && (
                      <span className="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-slate-100 text-slate-600">
                        Public
                      </span>
                    )}
                  </div>
                  <div className="text-sm text-slate-500 mt-1">
                    {keychain.numKeys} keys
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </section>

      <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-6 py-5 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-emerald-100 flex items-center justify-center">
              <BellIcon className="w-5 h-5 text-emerald-600" />
            </div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Notifications
              <span className="ml-2 text-sm font-normal text-slate-500">
                ({data.notifications.length})
              </span>
            </h2>
          </div>
        </div>
        <div className="p-6">
          {data.notifications.length === 0 ? (
            <p className="text-slate-500 text-center py-4">No notifications configured</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {data.notifications.map((notif) => (
                <span
                  key={notif.id}
                  className="inline-flex items-center px-3 py-1.5 rounded-lg text-sm font-medium bg-slate-100 text-slate-700 ring-1 ring-inset ring-slate-200"
                >
                  {unCamelCase(notif.trigger)}
                </span>
              ))}
            </div>
          )}
        </div>
      </section>
    </div>
  );
};

interface InfoCardProps {
  label: string;
  value: string;
  highlight?: boolean;
}

const InfoCard: React.FC<InfoCardProps> = ({ label, value, highlight = false }) => (
  <div
    className={`rounded-xl p-4 ${
      highlight
        ? `bg-gradient-to-br from-brand-violet to-brand-fuchsia text-white`
        : `bg-slate-50 border border-slate-100`
    }`}
  >
    <div className={`text-sm ${highlight ? `text-white/80` : `text-slate-500`}`}>
      {label}
    </div>
    <div
      className={`text-lg font-display font-semibold mt-1 ${highlight ? `text-white` : `text-slate-900`}`}
    >
      {value}
    </div>
  </div>
);

interface SubscriptionBadgeProps {
  status: string;
}

const SubscriptionBadge: React.FC<SubscriptionBadgeProps> = ({ status }) => {
  const styles: Record<string, string> = {
    paid: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
    trialing: `bg-sky-50 text-sky-700 ring-sky-600/20`,
    overdue: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    unpaid: `bg-red-50 text-red-700 ring-red-600/20`,
    pendingEmailVerification: `bg-slate-50 text-slate-600 ring-slate-500/20`,
    complimentary: `bg-violet-50 text-violet-700 ring-violet-600/20`,
  };

  const labels: Record<string, string> = {
    paid: `Paid`,
    trialing: `Trial`,
    overdue: `Overdue`,
    unpaid: `Unpaid`,
    pendingEmailVerification: `Pending`,
    complimentary: `Complimentary`,
  };

  return (
    <span
      className={`inline-flex items-center px-3 py-1.5 rounded-lg text-sm font-medium ring-1 ring-inset ${
        styles[status] ?? `bg-slate-50 text-slate-600 ring-slate-500/20`
      }`}
    >
      {labels[status] ?? status}
    </span>
  );
};

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString(`en-US`, {
    year: `numeric`,
    month: `short`,
    day: `numeric`,
  });
}

function unCamelCase(str: string): string {
  return str
    .replace(/([a-z])([A-Z])/g, `$1 $2`)
    .replace(/([A-Z]+)([A-Z][a-z])/g, `$1 $2`)
    .toLowerCase()
    .replace(/^\w/, (c) => c.toUpperCase());
}

export default ParentDetail;
