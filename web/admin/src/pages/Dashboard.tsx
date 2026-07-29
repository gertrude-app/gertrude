import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { StatusConfig } from '../components/TimeSeriesGraph';
import type { Result } from '@shared/pairql';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import BreakdownBar from '../components/BreakdownBar';
import CohortHealthSection from '../components/CohortHealthSection';
import ErrorState from '../components/ErrorState';
import {
  ArrowRightIcon,
  MicIcon,
  MonitorIcon,
  MusicIcon,
  SmartphoneIcon,
  TagIcon,
  UsersIcon,
} from '../components/Icons';
import InstallsGraph from '../components/InstallsGraph';
import LoadingState from '../components/LoadingState';
import MonthlySubscriptionRevenueGraph from '../components/MonthlySubscriptionRevenueGraph';
import SignupGraph from '../components/SignupGraph';

const MACOS_VERSION_NAMES: Record<string, string> = {
  '10.15': `Catalina`,
  '11': `Big Sur`,
  '12': `Monterey`,
  '13': `Ventura`,
  '14': `Sonoma`,
  '15': `Sequoia`,
  '26': `Tahoe`,
};

const colorForVersion = (version: string, seed: number): string => {
  const parsed = Number.parseInt(version, 10);
  const value = Number.isNaN(parsed)
    ? [...version].reduce((hash, char) => hash + char.charCodeAt(0), 0)
    : parsed;
  const hue = (value * 47 + seed) % 360;
  return `hsl(${hue}deg 72% 48%)`;
};

const macOSVersionLabel = (version: string): string => {
  const name = MACOS_VERSION_NAMES[version];
  return name ? `macOS ${version} ${name}` : `macOS ${version}`;
};

const podcastInstallStatusConfig: StatusConfig = {
  isSuccess: (status) => status === `paid`,
  isInfo: (status) => status === `trial`,
  isWarning: (status) => status === `connected` || status === `iap`,
};

const musicInstallStatusConfig: StatusConfig = {
  isSuccess: (status) => status === `paid`,
  isInfo: (status) => status === `connected`,
  isWarning: () => false,
};

type DashboardLoad = Promise<
  [
    Result<T.SubscriptionsOverview.Output>,
    Result<T.MacOverview.Output>,
    Result<T.IOSOverview.Output>,
    Result<T.PodcastOverview.Output>,
    Result<T.MusicOverview.Output>,
    Result<T.PlatformVersionStats.Output>,
    Result<T.CohortAnalysis.Output>,
    Result<T.AppNamingStats.Output>,
  ]
>;

let pendingDashboardLoad: { token: string | null; request: DashboardLoad } | null = null;

const loadDashboard = (): DashboardLoad => {
  const token = localStorage.getItem(`admin_token`);
  if (pendingDashboardLoad?.token === token) {
    return pendingDashboardLoad.request;
  }

  const request = Promise.all([
    client.subscriptionsOverview(),
    client.macOverview(),
    client.iOSOverview(),
    client.podcastOverview(),
    client.musicOverview(),
    client.platformVersionStats(),
    client.cohortAnalysis(),
    client.appNamingStats(),
  ]);
  pendingDashboardLoad = { token, request };
  void request.finally(() => {
    if (pendingDashboardLoad?.request === request) {
      pendingDashboardLoad = null;
    }
  });
  return request;
};

const Dashboard: React.FC = () => {
  const [overviewData, setOverviewData] = useState<T.SubscriptionsOverview.Output | null>(
    null,
  );
  const [macData, setMacData] = useState<T.MacOverview.Output | null>(null);
  const [platformVersionData, setPlatformVersionData] =
    useState<T.PlatformVersionStats.Output | null>(null);
  const [iosData, setIosData] = useState<T.IOSOverview.Output | null>(null);
  const [podcastData, setPodcastData] = useState<T.PodcastOverview.Output | null>(null);
  const [musicData, setMusicData] = useState<T.MusicOverview.Output | null>(null);
  const [cohortData, setCohortData] = useState<T.CohortAnalysis.Output | null>(null);
  const [appNamingCount, setAppNamingCount] = useState<number | null>(null);
  const [appNamingStats, setAppNamingStats] = useState<T.AppNamingStats.Output | null>(
    null,
  );
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isActive = true;

    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const [
        overviewResult,
        macResult,
        iosResult,
        podcastResult,
        musicResult,
        platformVersionResult,
        cohortResult,
        appNamingResult,
      ] = await loadDashboard();

      if (!isActive) return;

      if (overviewResult.isError) {
        setError(
          overviewResult.error?.debugMessage ?? `Failed to load subscription data`,
        );
        setLoading(false);
        return;
      }

      if (macResult.isError) {
        setError(macResult.error?.debugMessage ?? `Failed to load Mac data`);
        setLoading(false);
        return;
      }

      setOverviewData(overviewResult.value ?? null);
      setMacData(macResult.value ?? null);
      setIosData(iosResult.value ?? null);
      setPodcastData(podcastResult.value ?? null);
      setMusicData(musicResult.value ?? null);
      setPlatformVersionData(platformVersionResult.value ?? null);
      setCohortData(cohortResult.value ?? null);
      if (!appNamingResult.isError && appNamingResult.value) {
        setAppNamingCount(appNamingResult.value.above100k);
        setAppNamingStats(appNamingResult.value);
      }
      setLoading(false);
    };

    void fetchData();
    return () => {
      isActive = false;
    };
  }, []);

  if (loading) {
    return <LoadingState context="dashboard" />;
  }

  if (error) {
    return <ErrorState context="dashboard" error={error} />;
  }

  return (
    <div className="space-y-8 animate-fade-in pt-4 pb-16">
      {appNamingCount !== null && appNamingCount > 100 && (
        <Link
          to="/app-naming"
          className="flex items-center justify-between px-5 py-4 bg-gradient-to-r from-brand-violet/10 to-brand-fuchsia/10 border border-brand-violet/20 rounded-2xl hover:from-brand-violet/15 hover:to-brand-fuchsia/15 transition-all group"
        >
          <div>
            <p className="font-display font-semibold text-brand-violet">
              App Naming Queue
            </p>
            <p className="text-sm text-slate-600 mt-0.5">
              {appNamingCount} app{appNamingCount !== 1 ? `s` : ``} above 100K requests
              need names
            </p>
          </div>
          <div className="flex items-center gap-1.5 text-sm font-medium text-brand-violet group-hover:gap-2.5 transition-all">
            Review
            <ArrowRightIcon className="w-4 h-4" />
          </div>
        </Link>
      )}
      {overviewData && (
        <OverviewSection data={overviewData} platformVersionData={platformVersionData} />
      )}
      {cohortData && <CohortHealthSection data={cohortData} />}
      {macData && <MacSection data={macData} />}
      {iosData && <IOSSection data={iosData} />}
      {podcastData && <PodcastSection data={podcastData} />}
      {musicData && <MusicSection data={musicData} />}
      {appNamingStats && <AppNamingCard stats={appNamingStats} />}
    </div>
  );
};

interface OverviewSectionProps {
  data: T.SubscriptionsOverview.Output;
  platformVersionData: T.PlatformVersionStats.Output | null;
}

const OverviewSection: React.FC<OverviewSectionProps> = ({
  data,
  platformVersionData,
}) => {
  const freeCount =
    data.totalAccounts -
    data.fullPlanCount -
    data.mediumPlanCount -
    data.lightPlanCount -
    data.trialingCount;
  // monthly compensation from living room
  const LIVING_ROOM_MONTHLY = 150;
  const stats = [
    {
      label: `Protected People`,
      value: data.protectedChildren.toLocaleString(),
      highlight: true,
    },
    {
      label: `Annual Revenue`,
      value: `$${(data.annualRevenue + LIVING_ROOM_MONTHLY * 12).toLocaleString()}`,
    },
    {
      label: `Monthly Revenue`,
      value: `$${(data.monthlyRevenue + LIVING_ROOM_MONTHLY).toLocaleString()}`,
    },
    { label: `Full Plans`, value: data.fullPlanCount.toLocaleString() },
    { label: `Medium Plans`, value: data.mediumPlanCount.toLocaleString() },
    { label: `Light Plans`, value: data.lightPlanCount.toLocaleString() },
    { label: `Total Accounts`, value: data.totalAccounts.toLocaleString() },
  ];

  const signupItems = data.recentSignups.map((s) => ({
    date: s.date,
    status: s.engagement,
    email: s.email,
  }));

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100 flex flex-wrap justify-between items-center gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <UsersIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">Overview</h2>
        </div>
        <Link
          to="/parents"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-brand-violet hover:text-brand-fuchsia bg-brand-50 hover:bg-brand-100 rounded-lg transition-all group"
        >
          <span>Parents</span>
          <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
        </Link>
      </div>
      <div className="p-4 sm:p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3 sm:gap-4">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className={`rounded-xl p-4 ${
                stat.highlight
                  ? `bg-gradient-to-br from-brand-violet to-brand-fuchsia text-white`
                  : `bg-slate-50 border border-slate-100`
              }`}
            >
              <div
                className={`text-2xl font-display font-semibold ${
                  stat.highlight ? `text-white` : `text-slate-900`
                }`}
              >
                {stat.value}
              </div>
              <div
                className={`text-sm mt-1 ${
                  stat.highlight ? `text-white/80` : `text-slate-500`
                }`}
              >
                {stat.label}
              </div>
            </div>
          ))}
        </div>
        <BreakdownBar
          title="Plan Breakdown"
          total={data.totalAccounts}
          segments={[
            {
              label: `Full`,
              value: data.fullPlanCount,
              gradient: `from-brand-violet to-brand-fuchsia`,
            },
            {
              label: `Medium`,
              value: data.mediumPlanCount,
              gradient: `from-indigo-400 to-violet-500`,
            },
            {
              label: `Light`,
              value: data.lightPlanCount,
              gradient: `from-sky-400 to-blue-500`,
            },
            {
              label: `Free`,
              value: freeCount,
              gradient: `from-slate-300 to-slate-400`,
            },
          ]}
        />
        <div>
          <h3 className="font-display font-medium text-slate-900 mb-3">Recent Signups</h3>
          <SignupGraph signups={signupItems} />
        </div>
        <div>
          <h3 className="font-display font-medium text-slate-900 mb-3">
            Subscription Revenue
          </h3>
          <MonthlySubscriptionRevenueGraph
            months={data.monthlySubscriptionRevenue ?? []}
          />
        </div>
        {platformVersionData && <PlatformVersionBars data={platformVersionData} />}
      </div>
    </section>
  );
};

interface PlatformVersionBarsProps {
  data: T.PlatformVersionStats.Output;
}

const PlatformVersionBars: React.FC<PlatformVersionBarsProps> = ({ data }) => (
  <div>
    <div className="flex flex-wrap items-baseline justify-between gap-2 mb-3">
      <h3 className="font-display font-medium text-slate-900">OS Versions</h3>
      <span className="text-sm text-slate-500">
        Active in the last {data.activeDays} days
      </span>
    </div>
    <div className="bg-slate-50 rounded-xl p-5 border border-slate-100 space-y-5">
      <PlatformVersionBar
        name="macOS"
        totalLabel="active computers"
        platform={data.macos}
        colorSeed={19}
        versionLabel={macOSVersionLabel}
      />
      <PlatformVersionBar
        name="iOS"
        totalLabel="active devices"
        platform={data.ios}
        colorSeed={211}
      />
    </div>
  </div>
);

interface PlatformVersionBarProps {
  name: string;
  totalLabel: string;
  platform: T.PlatformVersionStats.Output[`macos`];
  colorSeed: number;
  versionLabel?: (version: string) => string;
}

const PlatformVersionBar: React.FC<PlatformVersionBarProps> = ({
  name,
  totalLabel,
  platform,
  colorSeed,
  versionLabel,
}) => {
  const percentages = platform.versions.map((version) =>
    platform.total > 0 ? (version.count / platform.total) * 100 : 0,
  );

  return (
    <div>
      <div className="flex items-baseline justify-between gap-3 mb-2">
        <div className="font-medium text-slate-800">{name}</div>
        <div className="text-xs text-slate-500">
          {platform.total.toLocaleString()} {totalLabel}
        </div>
      </div>
      <div className="h-4 bg-white rounded-full overflow-hidden flex gap-px">
        {platform.versions.map((version, index) => (
          <div
            key={version.version}
            className="h-full"
            style={{
              width: `${percentages[index]}%`,
              backgroundColor: colorForVersion(version.version, colorSeed),
            }}
          />
        ))}
      </div>
      <div className="flex flex-wrap gap-x-4 gap-y-1.5 mt-3 text-sm">
        {platform.versions.map((version, index) => (
          <div key={version.version} className="flex items-center gap-1.5">
            <div
              className="w-3 h-3 rounded-full shrink-0"
              style={{ backgroundColor: colorForVersion(version.version, colorSeed) }}
            />
            <span className="text-slate-600">
              {versionLabel?.(version.version) ?? `${name} ${version.version}`} (
              {version.count.toLocaleString()} · {percentages[index]?.toFixed(1)}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

interface MacSectionProps {
  data: T.MacOverview.Output;
}

const MacSection: React.FC<MacSectionProps> = ({ data }) => {
  const totalParents = data.activeParents + data.onboardedParents + data.noActionParents;
  const stats = [
    { label: `Active Parents`, value: data.activeParents.toLocaleString() },
    {
      label: `Protected Children`,
      value: data.childrenOfActiveParents.toLocaleString(),
      highlight: true,
    },
    { label: `All-Time Children`, value: data.allTimeChildren.toLocaleString() },
    { label: `All-Time Installs`, value: data.allTimeAppInstallations.toLocaleString() },
  ];

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-amber-500 to-orange-600 flex items-center justify-center shadow-lg shadow-amber-500/20">
            <MonitorIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">Mac App</h2>
        </div>
      </div>
      <div className="p-4 sm:p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className={`rounded-xl p-4 ${
                stat.highlight
                  ? `bg-gradient-to-br from-amber-500 to-orange-600 text-white`
                  : `bg-slate-50 border border-slate-100`
              }`}
            >
              <div
                className={`text-2xl font-display font-semibold ${
                  stat.highlight ? `text-white` : `text-slate-900`
                }`}
              >
                {stat.value}
              </div>
              <div
                className={`text-sm mt-1 ${
                  stat.highlight ? `text-white/80` : `text-slate-500`
                }`}
              >
                {stat.label}
              </div>
            </div>
          ))}
        </div>
        <BreakdownBar
          title="Parent Engagement"
          total={totalParents}
          segments={[
            {
              label: `Active`,
              value: data.activeParents,
              gradient: `from-amber-500 to-orange-600`,
            },
            {
              label: `Onboarded Only`,
              value: data.onboardedParents,
              gradient: `from-sky-400 to-blue-500`,
            },
            {
              label: `No Action`,
              value: data.noActionParents,
              gradient: `from-slate-300 to-slate-400`,
            },
          ]}
        />
      </div>
    </section>
  );
};

interface IOSSectionProps {
  data: T.IOSOverview.Output;
}

const IOSSection: React.FC<IOSSectionProps> = ({ data }) => (
  <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
    <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
      <div className="flex flex-wrap justify-between items-center gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <SmartphoneIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">
            Blocker App
          </h2>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Link
            to="/blocker"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
          >
            <span>Devices</span>
            <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
          </Link>
          <Link
            to="/blocker-stats"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
          >
            <span>Stats</span>
            <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
          </Link>
          <Link
            to="/ratings/blocker"
            className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
          >
            <span>Ratings</span>
            <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
          </Link>
        </div>
      </div>
    </div>
    <div className="p-4 sm:p-6 space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3 sm:gap-4">
        <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
          <div className="text-2xl font-display font-semibold text-slate-900">
            {data.adjustedLaunches.toLocaleString()}
          </div>
          <div className="text-sm mt-1 text-slate-500">Adjusted Launches</div>
        </div>
        <div className="bg-gradient-to-br from-sky-400 to-blue-500 rounded-xl p-4">
          <div className="text-2xl font-display font-semibold text-white">
            {data.totalSuccess.toLocaleString()}
          </div>
          <div className="text-sm mt-1 text-white/80">Total Success</div>
        </div>
        <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
          <div className="text-2xl font-display font-semibold text-slate-900">
            {data.successRate}%
          </div>
          <div className="text-sm mt-1 text-slate-500">Success Rate</div>
        </div>
        <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
          <div className="text-2xl font-display font-semibold text-red-500">
            {data.stuckIn18PlusPath.toLocaleString()}
          </div>
          <div className="text-sm mt-1 text-slate-500">18+ Failures</div>
        </div>
        <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
          <div className="text-2xl font-display font-semibold text-slate-900">
            {data.gertrudeSupervisionSuccess.toLocaleString()}
          </div>
          <div className="text-sm mt-1 text-slate-500">Gertrude Supervisions</div>
        </div>
      </div>

      <BreakdownBar
        title="Success Breakdown"
        total={data.totalSuccess}
        segments={[
          {
            label: `Screen Time`,
            value: data.screenTimeSuccess,
            gradient: `from-sky-400 to-blue-500`,
          },
          {
            label: `Configurated`,
            value: data.configuratorSuccess,
            gradient: `from-emerald-400 to-green-500`,
          },
          {
            label: `Supervised`,
            value: data.gertrudeSupervisionSuccess,
            gradient: `from-amber-400 to-orange-500`,
          },
          {
            label: `Connected`,
            value: data.nonSupervisedConnectionSuccess,
            gradient: `from-fuchsia-400 to-pink-500`,
          },
        ]}
      />

      <div>
        <h3 className="font-display font-medium text-slate-900 mb-3">Recent Installs</h3>
        <InstallsGraph installs={data.recentInstalls} />
      </div>
    </div>
  </section>
);

interface PodcastSectionProps {
  data: T.PodcastOverview.Output;
}

const PodcastSection: React.FC<PodcastSectionProps> = ({ data }) => {
  const breakdown = data.statusBreakdown;

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
        <div className="flex flex-wrap justify-between items-center gap-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
              <MicIcon className="w-5 h-5 text-white" />
            </div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Podcast App
            </h2>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Link
              to="/podcasts"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-emerald-600 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition-all group"
            >
              <span>Installs</span>
              <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
            </Link>
            <Link
              to="/ratings/podcasts"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-emerald-600 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition-all group"
            >
              <span>Ratings</span>
              <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
            </Link>
          </div>
        </div>
      </div>
      <div className="p-4 sm:p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3 sm:gap-4">
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.totalInstalls.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Total Installs</div>
          </div>
          <div className="bg-gradient-to-br from-emerald-400 to-green-500 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-white">
              {breakdown.paid.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-white/80">Subscribers</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {breakdown.complimentary.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Complimentary</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {(breakdown.connected + breakdown.trial).toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Trialing</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {breakdown.iap.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Legacy IAP</div>
            <div className="text-xs mt-0.5 text-slate-400">
              ≈${(breakdown.iap * 10).toLocaleString()}/yr potential
            </div>
          </div>
        </div>

        <BreakdownBar
          title="Subscription Status"
          total={data.totalInstalls}
          segments={[
            {
              label: `Paid`,
              value: breakdown.paid,
              gradient: `from-emerald-400 to-green-500`,
            },
            {
              label: `Complimentary`,
              value: breakdown.complimentary,
              gradient: `from-rose-400 to-pink-500`,
            },
            {
              label: `Connected`,
              value: breakdown.connected,
              gradient: `from-violet-400 to-purple-500`,
            },
            {
              label: `Trial`,
              value: breakdown.trial,
              gradient: `from-sky-400 to-blue-500`,
            },
            {
              label: `Legacy IAP`,
              value: breakdown.iap,
              gradient: `from-amber-400 to-orange-500`,
            },
            {
              label: `Expired`,
              value: breakdown.expired,
              gradient: `from-slate-300 to-slate-400`,
            },
          ]}
        />

        <BreakdownBar
          title="Device Breakdown"
          total={data.totalInstalls}
          segments={[
            {
              label: `iPhone`,
              value: data.iPhoneInstalls,
              gradient: `from-emerald-400 to-green-500`,
            },
            {
              label: `iPad`,
              value: data.iPadInstalls,
              gradient: `from-violet-400 to-purple-500`,
            },
          ]}
        />

        <div>
          <h3 className="font-display font-medium text-slate-900 mb-3">
            Recent Installs
          </h3>
          <InstallsGraph
            installs={data.recentInstalls}
            gradient="green"
            statusConfig={podcastInstallStatusConfig}
          />
        </div>
      </div>
    </section>
  );
};

interface MusicSectionProps {
  data: T.MusicOverview.Output;
}

const MusicSection: React.FC<MusicSectionProps> = ({ data }) => {
  const breakdown = data.statusBreakdown;

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100">
        <div className="flex flex-wrap justify-between items-center gap-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-fuchsia-500 to-violet-600 flex items-center justify-center shadow-lg shadow-fuchsia-500/20">
              <MusicIcon className="w-5 h-5 text-white" />
            </div>
            <h2 className="font-display font-semibold text-slate-900 text-xl">
              Music App
            </h2>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Link
              to="/music"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-fuchsia-600 hover:text-fuchsia-700 bg-fuchsia-50 hover:bg-fuchsia-100 rounded-lg transition-all group"
            >
              <span>Installs</span>
              <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
            </Link>
            <Link
              to="/ratings/music"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-fuchsia-600 hover:text-fuchsia-700 bg-fuchsia-50 hover:bg-fuchsia-100 rounded-lg transition-all group"
            >
              <span>Ratings</span>
              <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
            </Link>
          </div>
        </div>
      </div>
      <div className="p-4 sm:p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3 sm:gap-4">
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.totalInstalls.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Total Installs</div>
          </div>
          <div className="bg-gradient-to-br from-fuchsia-500 to-violet-600 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-white">
              {data.connectedMusicUsers.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-white/80">Connected Users</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.approvedAlbums.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Approved Albums</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.paidMusicFamilies.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Paid Music Families</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {breakdown.unclaimed.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Unclaimed</div>
          </div>
        </div>

        <BreakdownBar
          title="Connection Status"
          total={data.totalInstalls}
          segments={[
            {
              label: `Paid`,
              value: breakdown.paid,
              gradient: `from-fuchsia-500 to-violet-600`,
            },
            {
              label: `Complimentary`,
              value: breakdown.complimentary,
              gradient: `from-rose-400 to-pink-500`,
            },
            {
              label: `Connected`,
              value: breakdown.connected,
              gradient: `from-sky-400 to-blue-500`,
            },
            {
              label: `Unclaimed`,
              value: breakdown.unclaimed,
              gradient: `from-slate-300 to-slate-400`,
            },
          ]}
        />

        <BreakdownBar
          title="Device Breakdown"
          total={data.totalInstalls}
          segments={[
            {
              label: `iPhone`,
              value: data.iPhoneInstalls,
              gradient: `from-fuchsia-500 to-violet-600`,
            },
            {
              label: `iPad`,
              value: data.iPadInstalls,
              gradient: `from-violet-400 to-purple-500`,
            },
          ]}
        />

        <div>
          <h3 className="font-display font-medium text-slate-900 mb-3">
            Recent Installs
          </h3>
          <InstallsGraph
            installs={data.recentInstalls}
            gradient="fuchsia"
            statusConfig={musicInstallStatusConfig}
          />
        </div>
      </div>
    </section>
  );
};

interface AppNamingCardProps {
  stats: {
    total: number;
    above100k: number;
    above50k: number;
    above10k: number;
    above1k: number;
  };
}

const AppNamingCard: React.FC<AppNamingCardProps> = ({ stats }) => {
  const thresholds = [
    { label: `50K+`, value: stats.above50k },
    { label: `10K+`, value: stats.above10k },
    { label: `1K+`, value: stats.above1k },
  ];

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-4 sm:px-6 py-4 sm:py-5 border-b border-slate-100 flex flex-wrap justify-between items-center gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <TagIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">
            App Naming
          </h2>
        </div>
        <Link
          to="/app-naming"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-brand-violet hover:text-brand-fuchsia bg-brand-50 hover:bg-brand-100 rounded-lg transition-all group"
        >
          <span>Review</span>
          <ArrowRightIcon className="w-3.5 h-3.5 group-hover:translate-x-0.5 transition-transform" />
        </Link>
      </div>
      <div className="p-4 sm:p-6">
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 sm:gap-4">
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {stats.total.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Total Unnamed</div>
          </div>
          <div className="bg-gradient-to-br from-brand-violet to-brand-fuchsia rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-white">
              {stats.above100k.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-white/80">100K+ requests</div>
          </div>
          {thresholds.map((t) => (
            <div
              key={t.label}
              className="bg-slate-50 border border-slate-100 rounded-xl p-4"
            >
              <div className="text-2xl font-display font-semibold text-slate-900">
                {t.value.toLocaleString()}
              </div>
              <div className="text-sm mt-1 text-slate-500">{t.label} requests</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Dashboard;
