import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import BreakdownBar from '../components/BreakdownBar';
import ErrorState from '../components/ErrorState';
import {
  ArrowRightIcon,
  MicIcon,
  MonitorIcon,
  SmartphoneIcon,
} from '../components/Icons';
import InstallsGraph from '../components/InstallsGraph';
import LoadingState from '../components/LoadingState';
import PodcastInstallsGraph from '../components/PodcastInstallsGraph';
import SignupGraph from '../components/SignupGraph';

const Dashboard: React.FC = () => {
  const [macData, setMacData] = useState<T.MacOverview.Output | null>(null);
  const [iosData, setIosData] = useState<T.IOSOverview.Output | null>(null);
  const [podcastData, setPodcastData] = useState<T.PodcastOverview.Output | null>(null);
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
    return <LoadingState context="dashboard" />;
  }

  if (error) {
    return <ErrorState context="dashboard" error={error} />;
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
  data: T.MacOverview.Output;
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
  data: T.IOSOverview.Output;
}

const IOSSection: React.FC<IOSSectionProps> = ({ data }) => (
  <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
    <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center">
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-sky-400 to-blue-500 flex items-center justify-center shadow-lg shadow-sky-500/20">
          <SmartphoneIcon className="w-5 h-5 text-white" />
        </div>
        <h2 className="font-display font-semibold text-slate-900 text-xl">iOS App</h2>
      </div>
      <div className="flex items-center gap-2">
        <Link
          to="/ios-devices"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
        >
          <span>View Devices</span>
          <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
        </Link>
        <Link
          to="/ios-stats"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
        >
          <span>View Stats</span>
          <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
        </Link>
        <Link
          to="/ratings/blocker"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all group"
        >
          <span>View Ratings</span>
          <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
        </Link>
      </div>
    </div>
    <div className="p-6 space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
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
            {data.parentFalseStarts.toLocaleString()}
          </div>
          <div className="text-sm mt-1 text-slate-500">Parent False Starts</div>
        </div>
      </div>

      <BreakdownBar
        title="Success Breakdown"
        total={data.totalSuccess}
        segments={[
          {
            label: `Screen Time`,
            value: data.standardSuccess,
            gradient: `from-sky-400 to-blue-500`,
          },
          {
            label: `Supervision`,
            value: data.supervisedSuccess,
            gradient: `from-emerald-400 to-green-500`,
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
  const yearlyRevenue = Math.round(data.successfulSubscriptions * 10 * 0.85);

  return (
    <section className="bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
      <div className="px-6 py-5 border-b border-slate-100 flex justify-between items-center">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400 to-green-500 flex items-center justify-center shadow-lg shadow-emerald-500/20">
            <MicIcon className="w-5 h-5 text-white" />
          </div>
          <h2 className="font-display font-semibold text-slate-900 text-xl">
            Podcast App
          </h2>
        </div>
        <div className="flex items-center gap-2">
          <Link
            to="/podcasts"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-emerald-600 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition-all group"
          >
            <span>View Installs</span>
            <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
          </Link>
          <Link
            to="/ratings/podcasts"
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-emerald-600 hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 rounded-lg transition-all group"
          >
            <span>View Ratings</span>
            <ArrowRightIcon className="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
          </Link>
        </div>
      </div>
      <div className="p-6 space-y-6">
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
              {data.conversionRate}%
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
          <PodcastInstallsGraph installs={data.recentInstalls} />
        </div>
      </div>
    </section>
  );
};

export default Dashboard;
