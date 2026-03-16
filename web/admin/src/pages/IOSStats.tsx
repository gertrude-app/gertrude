import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { ArrowLeftIcon, SmartphoneIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Section from '../components/Section';
import StatCard from '../components/StatCard';

const IOSStats: React.FC = () => {
  const [data, setData] = useState<T.IOSDetailedStats.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const result = await client.iOSDetailedStats();

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load iOS stats`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, []);

  if (loading) {
    return <LoadingState context="iOS stats" gradient="blue" />;
  }

  if (error || !data) {
    return <ErrorState context="iOS stats" error={error ?? `Unknown error`} />;
  }

  const formatDateRange = (): string => {
    const start = new Date(data.dateRange.start);
    const end = new Date(data.dateRange.end);
    const options: Intl.DateTimeFormatOptions = {
      year: `numeric`,
      month: `long`,
      day: `numeric`,
    };
    return `${start.toLocaleDateString(`en-US`, options)} – ${end.toLocaleDateString(
      `en-US`,
      options,
    )}`;
  };

  const total18Plus =
    data.outcomes.stuckIn18Plus.count + data.installFailures.invalidAccountType;
  const total18PlusPct =
    data.overview.firstLaunches > 0
      ? ((total18Plus / data.overview.firstLaunches) * 100).toFixed(1)
      : `0`;

  return (
    <div className="space-y-6 animate-fade-in">
      <div className="flex items-center gap-4">
        <Link
          to="/"
          className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-900 bg-slate-100 hover:bg-slate-200 rounded-lg transition-all group"
        >
          <ArrowLeftIcon className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform" />
          <span>Back</span>
        </Link>
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <SmartphoneIcon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="font-display font-semibold text-slate-900 text-2xl">
              iOS App Stats
            </h1>
            <p className="text-sm text-slate-500">{formatDateRange()}</p>
          </div>
        </div>
      </div>

      <Section title="Overview">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard label="First Launches" value={data.overview.firstLaunches} />
          <StatCard label="Parent False Starts" value={data.overview.parentFalseStarts} />
          <StatCard
            label="Adjusted Launches"
            value={data.overview.adjustedLaunches}
            highlight="blue"
          />
          <StatCard
            label="Total Success"
            value={data.overview.totalSuccess}
            subvalue={`${data.overview.successPct}%`}
            highlight="green"
          />
        </div>
      </Section>

      <Section title="Outcomes">
        <div className="space-y-3">
          {[
            {
              label: `Success`,
              count: data.outcomes.success.count,
              pct: data.outcomes.success.pct,
              color: `bg-green-500`,
            },
            {
              label: `Problem: Stuck in 18+/major path`,
              count: data.outcomes.stuckIn18Plus.count,
              pct: data.outcomes.stuckIn18Plus.pct,
              color: `bg-red-400`,
            },
            {
              label: `Problem: Full install failed`,
              count: data.outcomes.fullInstallFailed.count,
              pct: data.outcomes.fullInstallFailed.pct,
              color: `bg-amber-400`,
            },
            {
              label: `False start: Parent device`,
              count: data.outcomes.parentDevice.count,
              pct: data.outcomes.parentDevice.pct,
              color: `bg-slate-300`,
            },
            {
              label: `False start: Child onboarding issue`,
              count: data.outcomes.childOnboardingIssue.count,
              pct: data.outcomes.childOnboardingIssue.pct,
              color: `bg-slate-300`,
            },
            {
              label: `Unknown: Quit early without error`,
              count: data.outcomes.earlyDrop.count,
              pct: data.outcomes.earlyDrop.pct,
              color: `bg-slate-300`,
            },
          ].map((item) => (
            <div
              key={item.label}
              className="space-y-1 sm:space-y-0 sm:flex sm:items-center sm:gap-4"
            >
              <div className="sm:w-64 text-sm text-slate-700">{item.label}</div>
              <div className="flex items-center gap-2 sm:gap-4 sm:flex-1">
                <div className="flex-1 h-5 sm:h-6 bg-slate-100 rounded-full overflow-hidden">
                  <div
                    className={`h-full ${item.color} rounded-full`}
                    style={{ width: `${item.pct}%` }}
                  />
                </div>
                <div className="flex gap-2 shrink-0">
                  <div className="w-10 sm:w-14 text-right text-sm font-medium text-slate-900">
                    {item.count.toLocaleString()}
                  </div>
                  <div className="w-12 text-right text-sm text-slate-400">
                    {item.pct}%
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Section>

      <Section title="Success Breakdown">
        <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
          <div className="flex justify-between items-baseline mb-3">
            <h3 className="font-display font-medium text-slate-900">Types</h3>
            <span className="text-sm text-slate-500">
              {data.overview.totalSuccess.toLocaleString()} total
            </span>
          </div>
          <div className="h-6 bg-slate-200 rounded-full overflow-hidden flex">
            <div
              className="h-full bg-gradient-to-r from-sky-400 to-blue-500"
              style={{ width: `${data.successBreakdown.screenTime.pctOfSuccess}%` }}
            />
            <div
              className="h-full bg-gradient-to-r from-emerald-400 to-green-500"
              style={{ width: `${data.successBreakdown.configurator.pctOfSuccess}%` }}
            />
            <div
              className="h-full bg-gradient-to-r from-amber-400 to-orange-500"
              style={{
                width: `${data.successBreakdown.gertrudeSupervision.pctOfSuccess}%`,
              }}
            />
            <div
              className="h-full bg-gradient-to-r from-fuchsia-400 to-pink-500"
              style={{
                width: `${data.successBreakdown.nonSupervisedConnection.pctOfSuccess}%`,
              }}
            />
          </div>
          <div className="flex flex-wrap justify-between mt-3 text-sm gap-y-2">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-sky-400 to-blue-500" />
              <span className="text-slate-600">
                Screen Time ({data.successBreakdown.screenTime.count.toLocaleString()} ·
                {` `}
                {data.successBreakdown.screenTime.pctOfSuccess}%)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-emerald-400 to-green-500" />
              <span className="text-slate-600">
                Configurated ({data.successBreakdown.configurator.count.toLocaleString()}
                {` `}·{` `}
                {data.successBreakdown.configurator.pctOfSuccess}%)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-amber-400 to-orange-500" />
              <span className="text-slate-600">
                Supervised (
                {data.successBreakdown.gertrudeSupervision.count.toLocaleString()} ·{` `}
                {data.successBreakdown.gertrudeSupervision.pctOfSuccess}%)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-fuchsia-400 to-pink-500" />
              <span className="text-slate-600">
                Connected (
                {data.successBreakdown.nonSupervisedConnection.count.toLocaleString()} ·
                {` `}
                {data.successBreakdown.nonSupervisedConnection.pctOfSuccess}%)
              </span>
            </div>
          </div>
        </div>
      </Section>

      <Section title="Supervision Pipeline">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3 sm:gap-4 mb-4">
          <StatCard
            label="Total Claims"
            value={data.supervision.totalClaims}
            highlight="blue"
          />
          <StatCard label="Pending Claim" value={data.supervision.pendingClaim} />
          <StatCard label="Claimed" value={data.supervision.claimed} />
          <StatCard label="Supervised" value={data.supervision.supervised} />
          <StatCard label="Complete" value={data.supervision.complete} />
        </div>
        {data.supervision.totalClaims > 0 && (
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
            <div className="flex justify-between items-baseline mb-3">
              <h3 className="font-display font-medium text-slate-900">Pipeline Status</h3>
              <span className="text-sm text-slate-500">
                {data.supervision.totalClaims.toLocaleString()} total
              </span>
            </div>
            <div className="h-6 bg-slate-200 rounded-full overflow-hidden flex">
              {[
                {
                  value: data.supervision.pendingClaim,
                  gradient: `from-slate-300 to-slate-400`,
                },
                {
                  value: data.supervision.claimed,
                  gradient: `from-amber-400 to-orange-500`,
                },
                {
                  value: data.supervision.supervised,
                  gradient: `from-sky-400 to-blue-500`,
                },
                {
                  value: data.supervision.complete,
                  gradient: `from-emerald-400 to-green-500`,
                },
              ].map((seg) => {
                const pct = (seg.value / data.supervision.totalClaims) * 100;
                return pct > 0 ? (
                  <div
                    key={seg.gradient}
                    className={`h-full bg-gradient-to-r ${seg.gradient}`}
                    style={{ width: `${pct}%` }}
                  />
                ) : null;
              })}
            </div>
            <div className="flex flex-wrap gap-x-6 gap-y-1 mt-3 text-sm">
              {[
                {
                  label: `Pending Claim`,
                  value: data.supervision.pendingClaim,
                  gradient: `from-slate-300 to-slate-400`,
                },
                {
                  label: `Claimed`,
                  value: data.supervision.claimed,
                  gradient: `from-amber-400 to-orange-500`,
                },
                {
                  label: `Supervised`,
                  value: data.supervision.supervised,
                  gradient: `from-sky-400 to-blue-500`,
                },
                {
                  label: `Complete`,
                  value: data.supervision.complete,
                  gradient: `from-emerald-400 to-green-500`,
                },
              ].map((item) => (
                <div key={item.label} className="flex items-center gap-2">
                  <div
                    className={`w-3 h-3 rounded-full bg-gradient-to-r ${item.gradient}`}
                  />
                  <span className="text-slate-600">
                    {item.label} ({item.value.toLocaleString()} ·{` `}
                    {((item.value / data.supervision.totalClaims) * 100).toFixed(1)}%)
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </Section>

      <Section title="18+ Account Impact">
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4 mb-4">
          <StatCard
            label="Stuck in Major Path"
            value={data.outcomes.stuckIn18Plus.count}
            subvalue="Never succeeded"
          />
          <StatCard
            label="Auth Failed (Invalid Account)"
            value={data.installFailures.invalidAccountType}
            subvalue="18+ account type"
          />
          <StatCard
            label="Total Affected"
            value={total18Plus}
            subvalue={`${total18PlusPct}% of launches`}
            highlight="red"
          />
        </div>
      </Section>

      <Section title="Install Failures">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <StatCard
            label="Invalid Account Type"
            value={data.installFailures.invalidAccountType}
          />
          <StatCard label="Auth Canceled" value={data.installFailures.authCanceled} />
          <StatCard label="Auth Restricted" value={data.installFailures.authRestricted} />
          <StatCard
            label="Filter Install Failed"
            value={data.installFailures.filterInstallFailed}
          />
        </div>
      </Section>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Section title="Device Types">
          <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
            <div className="flex justify-between items-baseline mb-3">
              <h3 className="font-display font-medium text-slate-900">Distribution</h3>
              <span className="text-sm text-slate-500">
                {(data.devices.iphone.count + data.devices.ipad.count).toLocaleString()}
                {` `}
                total
              </span>
            </div>
            <div className="h-6 bg-slate-200 rounded-full overflow-hidden flex">
              <div
                className="h-full bg-gradient-to-r from-emerald-400 to-green-500"
                style={{ width: `${data.devices.iphone.pct}%` }}
              />
              <div
                className="h-full bg-gradient-to-r from-blue-500 to-sky-400"
                style={{ width: `${data.devices.ipad.pct}%` }}
              />
            </div>
            <div className="flex justify-between mt-3 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-gradient-to-r from-emerald-400 to-green-500" />
                <span className="text-slate-600">
                  iPhone ({data.devices.iphone.count.toLocaleString()} ·{` `}
                  {data.devices.iphone.pct}%)
                </span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-gradient-to-r from-blue-500 to-sky-400" />
                <span className="text-slate-600">
                  iPad ({data.devices.ipad.count.toLocaleString()} ·{` `}
                  {data.devices.ipad.pct}%)
                </span>
              </div>
            </div>
          </div>
        </Section>

        <Section title="Top Regions">
          <div className="space-y-2">
            {(() => {
              const totalCount = data.topRegions.reduce((sum, r) => sum + r.count, 0);
              return data.topRegions.map((r) => {
                const pct = ((r.count / totalCount) * 100).toFixed(1);
                return (
                  <div
                    key={r.region}
                    className="flex items-center justify-between text-sm"
                  >
                    <span className="text-slate-700">
                      {r.name} <span className="text-slate-400">({r.region})</span>
                    </span>
                    <span>
                      <span className="font-medium text-slate-900">
                        {r.count.toLocaleString()}
                      </span>
                      <span className="text-slate-400"> ({pct}%)</span>
                    </span>
                  </div>
                );
              });
            })()}
          </div>
        </Section>
      </div>

      <Section title="Top iOS Versions">
        <div className="space-y-3">
          {(() => {
            const totalCount = data.topIOSVersions.reduce((sum, v) => sum + v.count, 0);
            return data.topIOSVersions.map((v) => {
              const pct = (v.count / totalCount) * 100;
              return (
                <div key={v.version} className="flex items-center gap-2 sm:gap-4">
                  <div className="w-16 sm:w-20 text-xs sm:text-sm font-medium text-slate-700 shrink-0">
                    iOS {v.version}
                  </div>
                  <div className="flex-1 h-5 sm:h-6 bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-sky-400 to-blue-500 rounded-full"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <div className="w-20 sm:w-28 text-right text-xs sm:text-sm font-medium text-slate-900 shrink-0">
                    {v.count.toLocaleString()} ({pct.toFixed(1)}%)
                  </div>
                </div>
              );
            });
          })()}
        </div>
      </Section>

      <Section title="Successful Install Events">
        <div className="space-y-2">
          {data.funnelEvents.map((e, i) => {
            const prevCount =
              i > 0 ? (data.funnelEvents[i - 1]?.count ?? e.count) : e.count;
            const dropoff = prevCount > 0 ? ((prevCount - e.count) / prevCount) * 100 : 0;
            return (
              <div key={e.id} className="flex items-center gap-2 sm:gap-4">
                <code className="text-xs text-slate-400 w-16 sm:w-20 shrink-0">
                  {e.id}
                </code>
                <div className="flex-1 text-xs sm:text-sm text-slate-700 min-w-0 truncate">
                  {e.name}
                </div>
                <div className="w-16 sm:w-24 text-right text-xs sm:text-sm font-medium text-slate-900 shrink-0">
                  {e.count.toLocaleString()}
                </div>
                {i > 0 && dropoff > 0 && (
                  <div className="w-14 sm:w-20 text-right text-xs text-red-500 shrink-0">
                    -{dropoff.toFixed(1)}%
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </Section>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Section title="Drop-off Events">
          <div className="space-y-2">
            {[...data.dropoffEvents]
              .sort((a, b) => b.count - a.count)
              .map((e) => (
                <div key={e.id} className="flex items-center gap-2 sm:gap-4">
                  <code className="text-xs text-slate-400 w-16 sm:w-20 shrink-0">
                    {e.id}
                  </code>
                  <div className="flex-1 text-xs sm:text-sm text-slate-700 min-w-0 truncate">
                    {e.name}
                  </div>
                  <div className="w-14 sm:w-20 text-right text-xs sm:text-sm font-medium text-slate-900 shrink-0">
                    {e.count.toLocaleString()}
                  </div>
                </div>
              ))}
          </div>
        </Section>

        <Section title="Error Events">
          <div className="space-y-2">
            {[...data.errorEvents]
              .sort((a, b) => b.count - a.count)
              .map((e) => (
                <div key={e.id} className="flex items-center gap-2 sm:gap-4">
                  <code className="text-xs text-slate-400 w-16 sm:w-20 shrink-0">
                    {e.id}
                  </code>
                  <div className="flex-1 text-xs sm:text-sm text-slate-700 min-w-0 truncate">
                    {e.name}
                  </div>
                  <div className="w-14 sm:w-20 text-right text-xs sm:text-sm font-medium text-red-500 shrink-0">
                    {e.count.toLocaleString()}
                  </div>
                </div>
              ))}
          </div>
        </Section>
      </div>

      <Section title="Cache Clearing">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <StatCard label="Started" value={data.cacheClearing.started} />
          <StatCard
            label="Completed"
            value={data.cacheClearing.completed}
            highlight="green"
          />
          <StatCard label="Success Rate" value={`${data.cacheClearing.successRate}%`} />
          <StatCard label="Errors" value={data.cacheClearing.errors} />
        </div>
        <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
          <div className="flex justify-between items-baseline mb-3">
            <h3 className="font-display font-medium text-slate-900">By Context</h3>
            <span className="text-sm text-slate-500">
              {data.cacheClearing.started.toLocaleString()} total started
            </span>
          </div>
          <div className="h-6 bg-slate-200 rounded-full overflow-hidden flex">
            {(() => {
              const onboardingPct =
                data.cacheClearing.started > 0
                  ? (data.cacheClearing.onboardingStarted / data.cacheClearing.started) *
                    100
                  : 0;
              const infoPct =
                data.cacheClearing.started > 0
                  ? (data.cacheClearing.infoStarted / data.cacheClearing.started) * 100
                  : 0;
              return (
                <>
                  <div
                    className="h-full bg-gradient-to-r from-violet-400 to-purple-500"
                    style={{ width: `${onboardingPct}%` }}
                  />
                  <div
                    className="h-full bg-gradient-to-r from-amber-400 to-orange-500"
                    style={{ width: `${infoPct}%` }}
                  />
                </>
              );
            })()}
          </div>
          <div className="flex justify-between mt-3 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-violet-400 to-purple-500" />
              <span className="text-slate-600">
                Onboarding ({data.cacheClearing.onboardingStarted} ·{` `}
                {data.cacheClearing.started > 0
                  ? (
                      (data.cacheClearing.onboardingStarted /
                        data.cacheClearing.started) *
                      100
                    ).toFixed(1)
                  : 0}
                %)
              </span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-gradient-to-r from-amber-400 to-orange-500" />
              <span className="text-slate-600">
                Info Screen ({data.cacheClearing.infoStarted} ·{` `}
                {data.cacheClearing.started > 0
                  ? (
                      (data.cacheClearing.infoStarted / data.cacheClearing.started) *
                      100
                    ).toFixed(1)
                  : 0}
                %)
              </span>
            </div>
          </div>
        </div>
      </Section>
    </div>
  );
};

export default IOSStats;
