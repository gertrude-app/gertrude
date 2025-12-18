import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import client, {
  type IOSOverviewOutput,
  type MacOverviewOutput,
  type PodcastOverviewOutput,
} from '../api/client';
import SignupGraph from '../components/SignupGraph';

interface IconProps {
  className?: string;
}

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

const SmartphoneIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <rect width="14" height="20" x="5" y="2" rx="2" ry="2" />
    <line x1="12" x2="12.01" y1="18" y2="18" />
  </svg>
);

const MicIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="M12 2a3 3 0 0 0-3 3v7a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3Z" />
    <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
    <line x1="12" x2="12" y1="19" y2="22" />
  </svg>
);

const ArrowRightIcon: React.FC<IconProps> = ({ className = `` }) => (
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
    <path d="M5 12h14" />
    <path d="m12 5 7 7-7 7" />
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

const Dashboard: React.FC = () => {
  const [macData, setMacData] = useState<MacOverviewOutput | null>(null);
  const [iosData, setIosData] = useState<IOSOverviewOutput | null>(null);
  const [podcastData, setPodcastData] = useState<PodcastOverviewOutput | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      setLoading(true);
      setError(null);

      const [macResult, iosResult, podcastResult] = await Promise.all([
        client.macOverview(),
        client.iOSOverview(),
        client.podcastOverview(),
      ]);

      if (macResult.isError) {
        setError(macResult.error?.debugMessage ?? `Failed to load Mac data`);
        setLoading(false);
        return;
      }

      setMacData(macResult.value ?? null);
      setIosData(iosResult.value ?? null);
      setPodcastData(podcastResult.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-24">
        <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center mb-4 shadow-lg shadow-brand-violet/20">
          <LoadingSpinner className="w-6 h-6 text-white" />
        </div>
        <p className="text-slate-500 font-medium">Loading dashboard...</p>
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
              Failed to load dashboard
            </h3>
            <p className="mt-1 text-red-700">{error}</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in pt-4">
      {macData && <MacSection data={macData} />}
      {iosData && <IOSSection data={iosData} />}
      {podcastData && <PodcastSection data={podcastData} />}
    </div>
  );
};

interface MacSectionProps {
  data: MacOverviewOutput;
}

const MacSection: React.FC<MacSectionProps> = ({ data }) => {
  const monthlyRevenue = Math.round(data.annualRevenue / 12);
  const stats = [
    { label: `Annual Revenue`, value: `$${data.annualRevenue.toLocaleString()}` },
    {
      label: `Monthly Revenue`,
      value: `$${monthlyRevenue.toLocaleString()}`,
      highlight: true,
    },
    { label: `Paying Parents`, value: data.payingParents.toLocaleString() },
    { label: `Active Parents`, value: data.activeParents.toLocaleString() },
    { label: `Active Children`, value: data.childrenOfActiveParents.toLocaleString() },
    { label: `All-Time Children`, value: data.allTimeChildren.toLocaleString() },
    { label: `All-Time Installs`, value: data.allTimeAppInstallations.toLocaleString() },
  ];

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-brand-violet to-brand-fuchsia flex items-center justify-center shadow-lg shadow-brand-violet/20">
            <MonitorIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">Mac App</h2>
        </div>
        <Link
          to="/parents"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-brand-violet hover:text-brand-fuchsia bg-brand-50 hover:bg-brand-100 rounded-lg transition-all group"
        >
          <span>View Parents</span>
          <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
        </Link>
      </div>
      <div className="p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-4">
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
                className={`text-sm mt-1 ${stat.highlight ? `text-white/80` : `text-slate-500`}`}
              >
                {stat.label}
              </div>
            </div>
          ))}
        </div>
        <div>
          <h3 className="font-display font-medium text-slate-900 mb-3">Recent Signups</h3>
          <SignupGraph signups={data.recentSignups} />
        </div>
      </div>
    </section>
  );
};

interface IOSSectionProps {
  data: IOSOverviewOutput;
}

const IOSSection: React.FC<IOSSectionProps> = ({ data }) => {
  const total = data.firstLaunches;
  const authPct = total > 0 ? (data.authorizationSuccesses / total) * 100 : 0;
  const installPct = total > 0 ? (data.filterInstallSuccesses / total) * 100 : 0;

  const stats = [
    { label: `First Launches`, value: data.firstLaunches.toLocaleString() },
    { label: `Auth Successes`, value: data.authorizationSuccesses.toLocaleString() },
    { label: `Filter Installs`, value: data.filterInstallSuccesses.toLocaleString() },
    {
      label: `Conversion Rate`,
      value: `${data.conversionRate.toFixed(1)}%`,
      highlight: true,
    },
  ];

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-6 py-5 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
            <SmartphoneIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">iOS App</h2>
        </div>
      </div>
      <div className="p-6 space-y-6">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {stats.map((stat) => (
            <div
              key={stat.label}
              className={`rounded-xl p-4 ${
                stat.highlight
                  ? `bg-gradient-to-br from-sky-400 to-blue-500 text-white`
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
                className={`text-sm mt-1 ${stat.highlight ? `text-white/80` : `text-slate-500`}`}
              >
                {stat.label}
              </div>
            </div>
          ))}
        </div>

        <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
          <h3 className="font-display font-medium text-slate-900 mb-4">
            Onboarding Funnel
          </h3>
          <div className="space-y-4">
            <FunnelBar
              label="First Launch"
              value={100}
              count={data.firstLaunches}
              gradient="from-sky-400 to-blue-500"
            />
            <FunnelBar
              label="Authorization"
              value={authPct}
              count={data.authorizationSuccesses}
              gradient="from-sky-400 to-blue-500"
            />
            <FunnelBar
              label="Filter Install"
              value={installPct}
              count={data.filterInstallSuccesses}
              gradient="from-sky-400 to-blue-500"
            />
          </div>
        </div>
      </div>
    </section>
  );
};

interface FunnelBarProps {
  label: string;
  value: number;
  count: number;
  gradient: string;
}

const FunnelBar: React.FC<FunnelBarProps> = ({ label, value, count, gradient }) => (
  <div className="space-y-1.5">
    <div className="flex justify-between items-baseline">
      <span className="text-sm font-medium text-slate-700">{label}</span>
      <span className="text-sm text-slate-500">
        {count.toLocaleString()} ({value.toFixed(1)}%)
      </span>
    </div>
    <div className="h-3 bg-slate-200 rounded-full overflow-hidden">
      <div
        className={`h-full bg-gradient-to-r ${gradient} rounded-full transition-all duration-700`}
        style={{ width: `${value}%` }}
      />
    </div>
  </div>
);

interface PodcastSectionProps {
  data: PodcastOverviewOutput;
}

const PodcastSection: React.FC<PodcastSectionProps> = ({ data }) => {
  const conversionRate =
    data.totalInstalls > 0
      ? ((data.successfulSubscriptions / data.totalInstalls) * 100).toFixed(1)
      : `0.0`;
  const yearlyRevenue = Math.round(data.successfulSubscriptions * 10 * 0.85);

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-6 py-5 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
            <MicIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">
            Podcast App
          </h2>
        </div>
      </div>
      <div className="p-6">
        <div className="grid grid-cols-4 gap-4">
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.totalInstalls.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Total Installs</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              {data.successfulSubscriptions.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Subscriptions</div>
          </div>
          <div className="bg-gradient-to-br from-emerald-400 to-green-500 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-white">
              {conversionRate}%
            </div>
            <div className="text-sm mt-1 text-white/80">Conversion</div>
          </div>
          <div className="bg-slate-50 border border-slate-100 rounded-xl p-4">
            <div className="text-2xl font-display font-semibold text-slate-900">
              ${yearlyRevenue.toLocaleString()}
            </div>
            <div className="text-sm mt-1 text-slate-500">Yearly Revenue</div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Dashboard;
