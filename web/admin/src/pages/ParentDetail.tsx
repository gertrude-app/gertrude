import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { StatusBadge } from '../components/Badge';
import { CopyButton, CopyLinkButton } from '../components/CopyButton';
import ErrorState from '../components/ErrorState';
import {
  AlertCircleIcon,
  ArrowLeftIcon,
  BellIcon,
  KeyIcon,
  LoadingSpinner,
  MonitorIcon,
  SmartphoneIcon,
  TrashIcon,
  UserIcon,
  UsersIcon,
  XIcon,
} from '../components/Icons';
import LoadingState from '../components/LoadingState';
import { formatDate, timeAgo, unCamelCase } from '../lib/format';

type Subscription = NonNullable<T.ParentDetail.Output[`subscription`]>;
type Entitlement = T.ParentDetail.Output[`entitlement`];
type TelemetryRow = T.GetParentRecentTelemetry.Output[number];

const TELEMETRY_RANGES: { label: string; hours: number }[] = [
  { label: `24h`, hours: 24 },
  { label: `7d`, hours: 24 * 7 },
  { label: `30d`, hours: 24 * 30 },
];

const ParentDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [data, setData] = useState<T.ParentDetail.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [confirmEmail, setConfirmEmail] = useState(``);
  const [deleteReason, setDeleteReason] = useState(``);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [telemetry, setTelemetry] = useState<TelemetryRow[] | null>(null);
  const [telemetryError, setTelemetryError] = useState<string | null>(null);
  const [telemetryHours, setTelemetryHours] = useState(24);
  const [telemetryErrorsOnly, setTelemetryErrorsOnly] = useState(false);

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

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    const fetchTelemetry = async (): Promise<void> => {
      const result = await client.getParentRecentTelemetry({
        parentId: id,
        sinceHours: telemetryHours,
        limit: 100,
      });
      if (cancelled) return;
      if (result.isError) {
        setTelemetry([]);
        setTelemetryError(result.error?.debugMessage ?? `Failed to load telemetry`);
      } else {
        setTelemetry(result.value ?? []);
        setTelemetryError(null);
      }
    };
    fetchTelemetry();
    return () => {
      cancelled = true;
    };
  }, [id, telemetryHours]);

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
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
          <div className="flex flex-col sm:flex-row sm:justify-between sm:items-start gap-3">
            <div className="flex items-center gap-3 sm:gap-4 min-w-0">
              <div className="w-10 h-10 sm:w-12 sm:h-12 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20 shrink-0">
                <UserIcon className="w-5 h-5 sm:w-6 sm:h-6 text-white" />
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1">
                  <h1 className="text-lg sm:text-xl font-display font-semibold text-slate-900 tracking-tight truncate">
                    {data.email}
                  </h1>
                  <CopyButton text={data.email} />
                </div>
                <div className="flex items-center gap-1 mt-0.5">
                  <p className="text-xs sm:text-sm text-slate-500 font-mono truncate">
                    {data.id.toLowerCase()}
                  </p>
                  <CopyButton text={data.id.toLowerCase()} />
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <IOSBadge children={data.children} />
              <StatusBadge status={data.status} size="md" />
            </div>
          </div>
        </div>

        <div className="p-4 sm:p-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4 mb-6">
            <PlanCard entitlement={data.entitlement} />
            <InfoCard
              label="Billing"
              value={billingLabel(data.entitlement, data.subscription)}
            />
            <InfoCard label="Children" value={data.children.length.toString()} />
            <InfoCard label="Created" value={formatDate(data.createdAt)} />
          </div>

          {(() => {
            const stripeId = data.subscription?.stripeId ?? null;
            if (!stripeId) return null;
            return (
              <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
                <span className="text-sm text-slate-500">Stripe: </span>
                <a
                  href={`https://dashboard.stripe.com/acct_1L8TXdGKRdhETuKA/subscriptions/${stripeId}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm font-mono text-brand-violet hover:text-brand-fuchsia transition-colors"
                >
                  {stripeId}
                </a>
              </div>
            );
          })()}
        </div>
      </div>

      <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
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
        <div className="p-4 sm:p-6">
          {data.children.length === 0 ? (
            <p className="text-slate-500 text-center py-4">No children configured</p>
          ) : (
            <div className="space-y-4">
              {data.children.map((child) => (
                <div
                  key={child.id}
                  className="border border-slate-200 rounded-xl p-5 hover:border-slate-300 transition-colors"
                >
                  <div className="flex flex-wrap items-center justify-between gap-2 mb-4">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-lg bg-sky-100 flex items-center justify-center shrink-0">
                        <UserIcon className="w-[18px] h-[18px] text-sky-600" />
                      </div>
                      <h3 className="font-display font-semibold text-slate-900 text-lg sm:text-xl">
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
                            className="bg-slate-50 rounded-xl p-3 sm:p-4 border border-slate-100 flex gap-3 sm:gap-4"
                          >
                            <div className="flex-shrink-0 w-14 h-14 sm:w-20 sm:h-20 bg-white rounded-lg border border-slate-200 flex items-center justify-center p-1.5 sm:p-2">
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
                              <div className="sm:flex sm:justify-between sm:items-start sm:gap-2">
                                <span className="font-medium text-slate-900">
                                  {install.modelTitle}
                                </span>
                                <span className="text-xs text-slate-400 block mt-0.5 sm:mt-0 sm:flex-shrink-0">
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

                  {child.iosDevices.length > 0 && (
                    <div className="mb-4">
                      <div className="flex items-center gap-2 mb-3">
                        <SmartphoneIcon className="w-4 h-4 text-slate-400" />
                        <h4 className="text-sm font-medium text-slate-700">
                          iOS devices ({child.iosDevices.length})
                        </h4>
                      </div>
                      <div className="grid gap-2">
                        {child.iosDevices.map((device) => (
                          <Link
                            key={device.id}
                            to={`/ios/${device.id.toLowerCase()}/events`}
                            className="bg-slate-50 rounded-xl p-3 sm:p-4 border border-slate-100 flex gap-3 sm:gap-4 hover:bg-slate-100 hover:border-slate-200 transition-colors"
                          >
                            <div className="flex-shrink-0 w-14 h-14 sm:w-20 sm:h-20 bg-white rounded-lg border border-slate-200 flex items-center justify-center p-1.5 sm:p-2">
                              <img
                                src={`https://parents.gertrude.app/ios/${
                                  device.modelIdentifier.startsWith(`iPad`)
                                    ? `iPad`
                                    : `iPhone`
                                }.png`}
                                alt={device.modelName}
                                className="max-w-full max-h-full object-contain"
                                onError={(e) => {
                                  (e.target as HTMLImageElement).style.display = `none`;
                                }}
                              />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="sm:flex sm:justify-between sm:items-start sm:gap-2">
                                <span className="font-medium text-slate-900">
                                  {device.modelName}
                                </span>
                                <div className="flex flex-wrap items-center gap-x-2 gap-y-1 mt-1 sm:mt-0 sm:flex-shrink-0">
                                  {device.supervisionStatus && (
                                    <SupervisionBadge status={device.supervisionStatus} />
                                  )}
                                  <span className="text-xs text-slate-400">
                                    {formatDate(device.createdAt)}
                                  </span>
                                </div>
                              </div>
                              <p className="text-xs text-slate-400 font-mono mt-0.5">
                                {device.modelIdentifier}
                              </p>
                              <div className="text-sm text-slate-600 mt-2 flex flex-wrap gap-x-4 gap-y-1">
                                <span>App v{device.appVersion}</span>
                                <span>iOS {device.iosVersion}</span>
                                {device.lastCheckin && (
                                  <span className="text-slate-400">
                                    Last seen {timeAgo(device.lastCheckin)}
                                  </span>
                                )}
                              </div>
                            </div>
                          </Link>
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
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
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
        <div className="p-4 sm:p-6">
          {data.keychains.length === 0 ? (
            <p className="text-slate-500 text-center py-4">No keychains configured</p>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 sm:gap-4">
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
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
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
        <div className="p-4 sm:p-6">
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

      <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-indigo-100 flex items-center justify-center">
                <MonitorIcon className="w-5 h-5 text-indigo-600" />
              </div>
              <h2 className="font-display font-semibold text-slate-900 text-xl">
                Recent API Activity
                <span className="ml-2 text-sm font-normal text-slate-500">
                  ({telemetry?.length ?? 0})
                </span>
              </h2>
            </div>
            <div className="flex items-center gap-2">
              {TELEMETRY_RANGES.map((r) => (
                <button
                  key={r.label}
                  onClick={() => setTelemetryHours(r.hours)}
                  className={`px-2.5 py-1 rounded-md text-xs font-medium transition-all ${
                    r.hours === telemetryHours
                      ? `bg-slate-900 text-white`
                      : `bg-slate-100 text-slate-600 hover:bg-slate-200`
                  }`}
                >
                  {r.label}
                </button>
              ))}
              <label className="flex items-center gap-2 text-xs text-slate-600 cursor-pointer select-none ml-2">
                <input
                  type="checkbox"
                  checked={telemetryErrorsOnly}
                  onChange={(e) => setTelemetryErrorsOnly(e.target.checked)}
                  className="rounded border-slate-300 text-slate-900 focus:ring-slate-900"
                />
                Errors only
              </label>
            </div>
          </div>
        </div>
        <div className="p-4 sm:p-6">
          {telemetryError ? (
            <p className="text-sm text-red-600">{telemetryError}</p>
          ) : (
            <TelemetryTable rows={telemetry} errorsOnly={telemetryErrorsOnly} />
          )}
        </div>
      </section>

      <section className="bg-white rounded-2xl border border-red-200 shadow-sm overflow-hidden">
        <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-red-100">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-red-100 flex items-center justify-center">
              <AlertCircleIcon className="w-5 h-5 text-red-600" />
            </div>
            <h2 className="font-display font-semibold text-red-900 text-xl">
              Danger Zone
            </h2>
          </div>
        </div>
        <div className="p-4 sm:p-6">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <h3 className="font-medium text-slate-900">Delete this parent</h3>
              <p className="text-sm text-slate-500 mt-1">
                Once deleted, this parent and all associated data will be permanently
                removed.
              </p>
            </div>
            <button
              onClick={() => setShowDeleteModal(true)}
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-red-700 bg-red-50 hover:bg-red-100 rounded-lg border border-red-200 transition-colors self-start sm:self-auto shrink-0"
            >
              <TrashIcon className="w-4 h-4" />
              Delete Parent
            </button>
          </div>
        </div>
      </section>

      {showDeleteModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl shadow-xl max-w-md w-full mx-4 overflow-hidden">
            <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
              <h2 className="font-display font-semibold text-slate-900 text-lg">
                Delete Parent
              </h2>
              <button
                onClick={() => {
                  setShowDeleteModal(false);
                  setConfirmEmail(``);
                  setDeleteReason(``);
                  setDeleteError(null);
                }}
                className="p-1 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <XIcon className="w-5 h-5 text-slate-400" />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                <p className="text-sm text-red-800">
                  This action cannot be undone. This will permanently delete the parent
                  account for <span className="font-semibold">{data.email}</span> and all
                  associated data.
                </p>
              </div>

              <div>
                <label
                  htmlFor="confirm-email"
                  className="block text-sm font-medium text-slate-700 mb-1.5"
                >
                  Type <span className="font-mono text-slate-900">{data.email}</span> to
                  confirm
                </label>
                <input
                  id="confirm-email"
                  type="text"
                  value={confirmEmail}
                  onChange={(e) => setConfirmEmail(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  placeholder="Enter email address"
                />
              </div>

              <div>
                <label
                  htmlFor="delete-reason"
                  className="block text-sm font-medium text-slate-700 mb-1.5"
                >
                  Reason for deletion
                </label>
                <input
                  id="delete-reason"
                  type="text"
                  value={deleteReason}
                  onChange={(e) => setDeleteReason(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
                  placeholder="e.g., User requested account deletion"
                />
              </div>

              {deleteError && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-3">
                  <p className="text-sm text-red-700">{deleteError}</p>
                </div>
              )}
            </div>
            <div className="px-6 py-4 bg-slate-50 border-t border-slate-100 flex justify-end gap-3">
              <button
                onClick={() => {
                  setShowDeleteModal(false);
                  setConfirmEmail(``);
                  setDeleteReason(``);
                  setDeleteError(null);
                }}
                className="px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={async () => {
                  setDeleting(true);
                  setDeleteError(null);
                  const result = await client.deleteParent({
                    parentId: data.id,
                    reason: deleteReason,
                  });
                  setDeleting(false);
                  if (result.isError) {
                    setDeleteError(
                      result.error?.debugMessage ?? `Failed to delete parent`,
                    );
                  } else {
                    navigate(`/parents`);
                  }
                }}
                disabled={
                  confirmEmail !== data.email || deleteReason.trim() === `` || deleting
                }
                className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 disabled:bg-red-300 disabled:cursor-not-allowed rounded-lg transition-colors"
              >
                {deleting && <LoadingSpinner className="w-4 h-4" />}
                Delete Parent
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

interface InfoCardProps {
  label: string;
  value: string;
}

const InfoCard: React.FC<InfoCardProps> = ({ label, value }) => (
  <div className="rounded-xl p-4 bg-slate-50 border border-slate-100">
    <div className="text-sm text-slate-500">{label}</div>
    <div className="text-lg font-display font-semibold mt-1 text-slate-900">{value}</div>
  </div>
);

const PLAN_TIER_CONFIG: Record<string, { label: string; bg: string; text: string }> = {
  full: { label: `Full`, bg: `from-brand-violet to-brand-fuchsia`, text: `text-white` },
  light: { label: `Light`, bg: `from-sky-400 to-blue-500`, text: `text-white` },
  free: { label: `Free`, bg: `from-slate-300 to-slate-400`, text: `text-white` },
};

function billingLabel(entitlement: Entitlement, sub: Subscription | undefined): string {
  switch (entitlement.case) {
    case `free`:
      return sub ? `Lapsed` : `No subscription`;
    case `light`:
      return sub?.stripeStatus === `pastDue` ? `Overdue — $10/yr` : `Paid — $10/yr`;
    case `complimentary`:
      return `Complimentary`;
    case `fullTrial`:
      return `Trial — ends ${formatDate(entitlement.until)}`;
    case `fullTrialGrace`:
      return `Trial expired`;
    case `full`: {
      const monthly = sub?.isLegacyPrice ? 5 : 10;
      return sub?.stripeStatus === `pastDue`
        ? `Overdue — $${monthly}/mo`
        : `Paid — $${monthly}/mo`;
    }
  }
}

const PlanCard: React.FC<{ entitlement: Entitlement }> = ({ entitlement }) => {
  const planKey =
    entitlement.case === `complimentary` ||
    entitlement.case === `fullTrial` ||
    entitlement.case === `fullTrialGrace`
      ? `full`
      : entitlement.case;
  const fallback = {
    label: `Free`,
    bg: `from-slate-300 to-slate-400`,
    text: `text-white`,
  };
  const tier = PLAN_TIER_CONFIG[planKey] ?? fallback;
  return (
    <div className={`rounded-xl p-4 bg-gradient-to-br ${tier.bg} ${tier.text}`}>
      <div className="text-sm opacity-80">Plan</div>
      <div className="text-lg font-display font-semibold mt-1">{tier.label}</div>
    </div>
  );
};

const SUPERVISION_CONFIG: Record<
  string,
  { label: string; bg: string; text: string; ring: string }
> = {
  complete: {
    label: `Supervised`,
    bg: `bg-emerald-50`,
    text: `text-emerald-700`,
    ring: `ring-emerald-600/20`,
  },
  supervised: {
    label: `Missing Profile`,
    bg: `bg-amber-50`,
    text: `text-amber-700`,
    ring: `ring-amber-600/20`,
  },
  claimed: {
    label: `Claimed`,
    bg: `bg-amber-50`,
    text: `text-amber-700`,
    ring: `ring-amber-600/20`,
  },
  pendingClaim: {
    label: `Pending Claim`,
    bg: `bg-slate-100`,
    text: `text-slate-600`,
    ring: `ring-slate-500/20`,
  },
  connected: {
    label: `Connected`,
    bg: `bg-teal-50`,
    text: `text-teal-700`,
    ring: `ring-teal-600/20`,
  },
};

const SupervisionBadge: React.FC<{ status: string }> = ({ status }) => {
  const config = SUPERVISION_CONFIG[status] ?? {
    label: status,
    bg: `bg-slate-100`,
    text: `text-slate-600`,
    ring: `ring-slate-500/20`,
  };
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium ${config.bg} ${config.text} ring-1 ring-inset ${config.ring}`}
    >
      {config.label}
    </span>
  );
};

const TelemetryTable: React.FC<{
  rows: TelemetryRow[] | null;
  errorsOnly: boolean;
}> = ({ rows, errorsOnly }) => {
  if (rows === null) {
    return <p className="text-sm text-slate-500">Loading…</p>;
  }
  const visible = errorsOnly ? rows.filter((r) => r.result !== `ok`) : rows;
  if (visible.length === 0) {
    return (
      <p className="text-sm text-slate-500">
        {errorsOnly ? `No errors in this range.` : `No API activity in this range.`}
      </p>
    );
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="border-b border-slate-200 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
            <th className="py-2 pr-3">When</th>
            <th className="py-2 px-3">Result</th>
            <th className="py-2 px-3">Domain</th>
            <th className="py-2 px-3">Operation</th>
            <th className="py-2 px-3 text-right">Dur</th>
            <th className="py-2 px-3 text-right">Req</th>
            <th className="py-2 px-3 text-right">Resp</th>
            <th className="py-2 px-3">Error</th>
            <th className="py-2 pl-3">UA</th>
          </tr>
        </thead>
        <tbody>
          {visible.map((r) => (
            <tr key={r.id} className="border-b border-slate-100">
              <td className="py-2 pr-3 whitespace-nowrap text-slate-600">
                {timeAgo(r.createdAt)}
              </td>
              <td className="py-2 px-3">
                <span className={`text-xs font-medium ${telemetryResultColor(r.result)}`}>
                  {r.result}
                </span>
              </td>
              <td className="py-2 px-3 text-slate-500">{r.domain}</td>
              <td className="py-2 px-3 font-medium text-slate-900">{r.operation}</td>
              <td className="py-2 px-3 text-right text-slate-500">{r.durationMs}ms</td>
              <td className="py-2 px-3 text-right text-slate-500">
                {formatBytesShort(r.numRequestBytes)}
              </td>
              <td className="py-2 px-3 text-right text-slate-500">
                {formatBytesShort(r.numResponseBytes)}
              </td>
              <td className="py-2 px-3 text-slate-700 text-xs">{r.errorType ?? `—`}</td>
              <td
                className="py-2 pl-3 text-xs text-slate-500 max-w-[180px] truncate"
                title={r.userAgent ?? ``}
              >
                {r.userAgent ?? `—`}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

function telemetryResultColor(result: string): string {
  switch (result) {
    case `unexpected_error`:
      return `text-red-600`;
    case `pql_error`:
    case `convertible_error`:
      return `text-amber-600`;
    case `not_found`:
      return `text-slate-500`;
    case `ok`:
      return `text-emerald-600`;
    default:
      return `text-slate-700`;
  }
}

function formatBytesShort(n: number | null | undefined): string {
  if (n === null || n === undefined) return `—`;
  if (n < 1024) return `${n}B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)}K`;
  return `${(n / (1024 * 1024)).toFixed(1)}M`;
}

function iosStatus(
  children: T.ParentDetail.Output[`children`],
): { label: string; style: string } | null {
  const devices = children.flatMap((c) => c.iosDevices);
  if (devices.length === 0) return null;
  const statuses = devices.map((d) => d.supervisionStatus).filter(Boolean);
  if (statuses.includes(`complete`))
    return {
      label: `iOS: Supervised`,
      style: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
    };
  if (
    statuses.includes(`supervised`) ||
    statuses.includes(`claimed`) ||
    statuses.includes(`pendingClaim`)
  )
    return {
      label: `iOS: Pending`,
      style: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    };
  return {
    label: `iOS: Connected`,
    style: `bg-teal-50 text-teal-700 ring-teal-600/20`,
  };
}

const IOSBadge: React.FC<{ children: T.ParentDetail.Output[`children`] }> = ({
  children,
}) => {
  const info = iosStatus(children);
  if (!info) return null;
  return (
    <span
      className={`inline-flex items-center px-3 py-1.5 text-sm rounded-lg font-medium ring-1 ring-inset ${info.style}`}
    >
      {info.label}
    </span>
  );
};

export default ParentDetail;
