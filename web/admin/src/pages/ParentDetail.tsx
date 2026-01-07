import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { StatusBadge, getSubscriptionLabel } from '../components/Badge';
import { CopyButton, CopyLinkButton } from '../components/CopyButton';
import ErrorState from '../components/ErrorState';
import {
  ArrowLeftIcon,
  BellIcon,
  KeyIcon,
  MonitorIcon,
  UserIcon,
  UsersIcon,
} from '../components/Icons';
import LoadingState from '../components/LoadingState';
import { formatDate, unCamelCase } from '../lib/format';

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
    return <LoadingState context="parent details" />;
  }

  if (error) {
    return <ErrorState context="parent" error={error} />;
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
          <StatusBadge status={data.status} size="md" />
        </div>

        <div className="p-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            <InfoCard
              label="Subscription"
              value={getSubscriptionLabel(data.subscriptionStatus)}
            />
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
                    <div className="mb-4">
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

                  {child.keychains.length > 0 && (
                    <div>
                      <div className="flex items-center gap-2 mb-3">
                        <KeyIcon className="w-4 h-4 text-slate-400" />
                        <h4 className="text-sm font-medium text-slate-700">
                          Keychains ({child.keychains.length})
                        </h4>
                      </div>
                      <div className="flex flex-wrap gap-2">
                        {child.keychains.map((keychain) => (
                          <div
                            key={keychain.id}
                            className="bg-slate-50 rounded-lg px-3 py-2 border border-slate-100 flex items-center gap-2"
                          >
                            <span className="text-sm font-medium text-slate-700">
                              {keychain.name}
                            </span>
                            <span className="text-xs text-slate-400">
                              ({keychain.numKeys} keys)
                            </span>
                            {keychain.isPublic && (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-slate-200 text-slate-600">
                                Public
                              </span>
                            )}
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
      className={`text-lg font-display font-semibold mt-1 ${
        highlight ? `text-white` : `text-slate-900`
      }`}
    >
      {value}
    </div>
  </div>
);

export default ParentDetail;
