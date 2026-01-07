import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import ErrorState from '../components/ErrorState';
import { ArrowLeftIcon, MicIcon, SmartphoneIcon, StarIcon } from '../components/Icons';
import LoadingState from '../components/LoadingState';
import Section from '../components/Section';
import StatCard from '../components/StatCard';
import { formatDate } from '../lib/format';

type GertrudeApp = `blocker` | `podcasts`;

const BACKFILL_DATE = `2026-01-06T00:00:00Z`;

const BACKFILL: Record<GertrudeApp, { stars: Record<number, number> }> = {
  blocker: { stars: { 5: 62, 2: 1 } },
  podcasts: { stars: { 5: 6 } },
};

type TimelineItem =
  | { type: `apiItem`; item: T.AppRatings.Output[`items`][number] }
  | { type: `backfill`; stars: Record<number, number>; date: string };

const AppRatings: React.FC = () => {
  const { app } = useParams<{ app: GertrudeApp }>();
  const [data, setData] = useState<T.AppRatings.Output | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async (): Promise<void> => {
      if (!app || (app !== `blocker` && app !== `podcasts`)) {
        setError(`Invalid app parameter`);
        setLoading(false);
        return;
      }

      setLoading(true);
      setError(null);

      const result = await client.appRatings({ app });

      if (result.isError) {
        setError(result.error?.debugMessage ?? `Failed to load ratings`);
        setLoading(false);
        return;
      }

      setData(result.value ?? null);
      setLoading(false);
    };

    fetchData();
  }, [app]);

  if (loading) {
    return (
      <LoadingState context="ratings" gradient={app === `blocker` ? `blue` : `green`} />
    );
  }

  if (error || !data) {
    return <ErrorState context="ratings" error={error ?? `Unknown error`} />;
  }

  const appName = app === `blocker` ? `Gertrude Blocker` : `Gertrude AM`;
  const Icon = app === `blocker` ? SmartphoneIcon : MicIcon;
  const gradientClass =
    app === `blocker` ? `from-sky-400 to-blue-500` : `from-emerald-400 to-green-500`;
  const shadowClass = app === `blocker` ? `shadow-sky-500/20` : `shadow-emerald-500/20`;
  const validApp = app === `podcasts` ? `podcasts` : `blocker`;
  const backfill = BACKFILL[validApp];
  const numReviews = data.items.filter((i) => i.type === `review`).length;

  const timelineItems: TimelineItem[] = [
    ...data.items.map((item) => ({ type: `apiItem` as const, item })),
    { type: `backfill` as const, stars: backfill.stars, date: BACKFILL_DATE },
  ].sort((a, b) => {
    const dateA = a.type === `backfill` ? a.date : a.item.date;
    const dateB = b.type === `backfill` ? b.date : b.item.date;
    return new Date(dateB).getTime() - new Date(dateA).getTime();
  });

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
          <div
            className={`w-10 h-10 rounded-xl bg-gradient-to-br ${gradientClass} flex items-center justify-center shadow-lg ${shadowClass}`}
          >
            <Icon className="w-5 h-5 text-white" />
          </div>
          <div>
            <h1 className="font-display font-semibold text-slate-900 text-2xl">
              {appName} Ratings
            </h1>
            <p className="text-sm text-slate-500">
              {data.totalCount} total ratings · {data.currentAverage.toFixed(1)} average
            </p>
          </div>
        </div>
      </div>

      <Section title="Overview">
        <div className="grid grid-cols-3 gap-4">
          <StatCard label="Total Ratings" value={data.totalCount} />
          <StatCard
            label="Average Rating"
            value={data.currentAverage.toFixed(1)}
            highlight={app === `blocker` ? `blue` : `green`}
          />
          <StatCard label="Reviews" value={numReviews} />
        </div>
      </Section>

      <Section title="Ratings Timeline">
        <div className="space-y-4">
          {timelineItems.map((item) =>
            item.type === `backfill` ? (
              <BackfillItem key="backfill" stars={item.stars} date={item.date} />
            ) : (
              <RatingItem key={getItemId(item.item)} item={item.item} />
            ),
          )}
          {timelineItems.length === 0 && (
            <div className="text-center py-8 text-slate-500">
              No ratings or reviews yet
            </div>
          )}
        </div>
      </Section>
    </div>
  );
};

function getItemId(item: T.AppRatings.Output[`items`][number]): string {
  return `${item.type}-${item.id}`;
}

const RatingItem: React.FC<{ item: T.AppRatings.Output[`items`][number] }> = ({
  item,
}) => {
  const dateStr = formatDate(item.date);

  if (item.type === `review`) {
    return (
      <div className="bg-white rounded-xl p-4 border border-slate-200 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <Stars count={item.stars} />
              <span className="text-slate-400">·</span>
              <span className="text-sm text-slate-500">{dateStr}</span>
            </div>
            {item.title && (
              <h3 className="font-medium text-slate-900 mb-1">{item.title}</h3>
            )}
            <p className="text-slate-600 text-sm">{item.body}</p>
            <div className="mt-2 text-xs text-slate-400">
              — {item.reviewer}, {item.territory}
            </div>
          </div>
        </div>
      </div>
    );
  } else {
    return (
      <div className="bg-slate-50 rounded-xl p-4 border border-slate-100">
        <div className="flex items-center gap-3">
          <Stars count={item.stars} />
          <span className="text-slate-400">·</span>
          <span className="text-sm text-slate-500">{dateStr}</span>
          <span className="text-xs text-slate-400">(rating only, no review)</span>
        </div>
      </div>
    );
  }
};

const BackfillItem: React.FC<{ stars: Record<number, number>; date: string }> = ({
  stars,
  date,
}) => {
  const total = Object.values(stars).reduce((sum, count) => sum + count, 0);
  const starBreakdown = [5, 4, 3, 2, 1]
    .filter((rating) => stars[rating])
    .map((rating) => `${stars[rating]} × ${rating}-star`)
    .join(`, `);

  return (
    <div className="bg-amber-50 rounded-xl p-4 border border-amber-200">
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center flex-shrink-0">
          <span className="text-amber-600 text-lg" role="img" aria-label="chart">
            📊
          </span>
        </div>
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="font-medium text-amber-900">
              {total} ratings before tracking started
            </span>
            <span className="text-amber-400">·</span>
            <span className="text-sm text-amber-700">{formatDate(date)}</span>
          </div>
          <div className="text-sm text-amber-700">{starBreakdown}</div>
        </div>
      </div>
    </div>
  );
};

const Stars: React.FC<{ count: number }> = ({ count }) => (
  <div className="flex items-center gap-0.5">
    {[1, 2, 3, 4, 5].map((star) => (
      <StarIcon
        key={star}
        className={`w-4 h-4 ${star <= count ? `text-amber-400` : `text-slate-200`}`}
        filled={star <= count}
      />
    ))}
  </div>
);

export default AppRatings;
