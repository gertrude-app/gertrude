import React, { useCallback, useEffect, useRef, useState } from 'react';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { CheckIcon, LoadingSpinner } from '../components/Icons';

type UnidentifiedApp = T.GetUnidentifiedApps.Output[`apps`][number];

const CATEGORIES = [
  { id: `7abf7b9c-ac52-4e16-98ff-8d4a6210b5b0`, slug: `browser`, name: `Browser` },
  { id: `387c4e96-e64d-4e9d-b2bd-120ce0f0fb4e`, slug: `chat`, name: `Chat` },
  { id: `34cf5f50-da40-48fd-9695-179e8ff36712`, slug: `email`, name: `Email` },
  { id: `236783ce-082e-4865-a02e-696fcad4895c`, slug: `games`, name: `Games` },
  {
    id: `17f7b151-abec-42f0-80cf-5a69c41fa7ea`,
    slug: `programming`,
    name: `Programming`,
  },
  {
    id: `899420a3-a219-481e-bebd-f90bea29c565`,
    slug: `social-media`,
    name: `Social Media`,
  },
  { id: `c76225fa-75a1-4c53-9593-59269ec6cba7`, slug: `ssh`, name: `SSH` },
  {
    id: `ec00e385-0581-4d7f-971c-c06228de3260`,
    slug: `sys-utils`,
    name: `System Utilities`,
  },
  { id: `89594a16-79d4-4084-982b-a30a72c4f597`, slug: `utils`, name: `Utilities` },
];

const ITUNES_GENRE_TO_SLUG: Record<string, string> = {
  Games: `games`,
  'Social Networking': `social-media`,
  Utilities: `utils`,
  'Developer Tools': `programming`,
};

interface ItunesHit {
  app: UnidentifiedApp;
  itunesName: string;
  developer: string;
  iconUrl: string;
  primaryGenre: string;
  editedName: string;
  slug: string;
  categoryId: string;
  promoting: boolean;
  promoted: boolean;
  error: string | null;
}

function normalizedBundleId(bundleId: string): string {
  const stripped = bundleId.startsWith(`.`) ? bundleId.slice(1) : bundleId;
  const parts = stripped.split(`.`);
  const first = parts[0] ?? ``;
  if (parts.length > 1 && /^[A-Z0-9]{10}$/.test(first)) {
    return parts.slice(1).join(`.`);
  }
  return stripped;
}

function toSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, `-`)
    .replace(/^-|-$/g, ``);
}

const AppNamingScan: React.FC = () => {
  const [apps, setApps] = useState<UnidentifiedApp[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [scanning, setScanning] = useState(false);
  const [scannedCount, setScannedCount] = useState(0);
  const [hits, setHits] = useState<ItunesHit[]>([]);
  const scanAbortRef = useRef(false);

  useEffect(() => {
    const load = async (): Promise<void> => {
      const result = await client.getUnidentifiedApps({ threshold: 1, limit: 0 });
      if (result.isError) {
        setLoadError(`Failed to load apps`);
        setLoading(false);
        return;
      }
      setApps(result.value?.apps ?? []);
      setLoading(false);
    };
    load();
  }, []);

  const startScan = useCallback(async () => {
    scanAbortRef.current = false;
    setScanning(true);
    setScannedCount(0);
    setHits([]);

    for (const [i, app] of apps.entries()) {
      if (scanAbortRef.current) break;
      const bundleId = normalizedBundleId(app.bundleId);
      try {
        const resp = await fetch(
          `https://itunes.apple.com/lookup?bundleId=${encodeURIComponent(bundleId)}`,
        );
        const data = await resp.json();
        if (data.resultCount > 0) {
          const r = data.results[0];
          const name: string = r.trackName ?? r.collectionName ?? bundleId;
          const primaryGenre: string = r.primaryGenreName ?? ``;
          const genreSlug = ITUNES_GENRE_TO_SLUG[primaryGenre];
          setHits((prev) => [
            ...prev,
            {
              app,
              itunesName: name,
              developer: r.sellerName ?? r.artistName ?? ``,
              iconUrl: r.artworkUrl60 ?? ``,
              primaryGenre,
              editedName: name,
              slug: toSlug(name),
              categoryId: genreSlug ?? ``,
              promoting: false,
              promoted: false,
              error: null,
            },
          ]);
        }
      } catch {
        // skip failed lookups
      }
      setScannedCount(i + 1);
      if (!scanAbortRef.current && i < apps.length - 1) {
        await new Promise((r) => setTimeout(r, 350));
      }
    }
    setScanning(false);
  }, [apps]);

  const stopScan = useCallback(() => {
    scanAbortRef.current = true;
  }, []);

  const updateHit = useCallback((bundleId: string, updates: Partial<ItunesHit>) => {
    setHits((prev) =>
      prev.map((h) => (h.app.bundleId === bundleId ? { ...h, ...updates } : h)),
    );
  }, []);

  const promoteHit = useCallback(
    async (hit: ItunesHit) => {
      if (!hit.editedName.trim() || !hit.slug.trim()) {
        updateHit(hit.app.bundleId, { error: `Name and slug required` });
        return;
      }
      updateHit(hit.app.bundleId, { promoting: true, error: null });

      const matchedCategory = CATEGORIES.find((c) => c.slug === hit.categoryId);
      const result = await client.promoteApp({
        bundleId: hit.app.bundleId,
        newApp: {
          name: hit.editedName.trim(),
          slug: hit.slug.trim(),
          categoryId: matchedCategory?.id || undefined,
          launchable: true,
        },
      });

      if (result.isError) {
        updateHit(hit.app.bundleId, {
          promoting: false,
          error: result.error?.userMessage ?? result.error?.debugMessage ?? `Failed`,
        });
      } else {
        updateHit(hit.app.bundleId, { promoting: false, promoted: true });
      }
    },
    [updateHit],
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <LoadingSpinner className="w-6 h-6 text-slate-300" />
      </div>
    );
  }

  if (loadError) {
    return <p className="text-red-500 text-sm py-8 text-center">{loadError}</p>;
  }

  const activeHits = hits.filter((h) => !h.promoted);
  const promotedCount = hits.filter((h) => h.promoted).length;

  return (
    <div className="space-y-6 animate-fade-in pt-4 pb-16">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-display font-semibold text-slate-900">
            iTunes Scan
          </h1>
          <p className="text-slate-500 text-sm mt-1">
            Scan {apps.length.toLocaleString()} unnamed apps against the iTunes API
          </p>
        </div>
        <div className="flex items-center gap-3">
          {scanning ? (
            <>
              <div className="text-sm text-slate-500">
                {scannedCount.toLocaleString()} / {apps.length.toLocaleString()} scanned
                <span className="mx-2 text-slate-300">|</span>
                <span className="text-brand-violet font-medium">
                  {hits.length} hit{hits.length !== 1 ? `s` : ``}
                </span>
                {promotedCount > 0 && (
                  <>
                    <span className="mx-2 text-slate-300">|</span>
                    <span className="text-emerald-600 font-medium">
                      {promotedCount} promoted
                    </span>
                  </>
                )}
              </div>
              <button
                onClick={stopScan}
                className="px-4 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors"
              >
                Stop
              </button>
            </>
          ) : (
            <>
              {scannedCount > 0 && (
                <div className="text-sm text-slate-500">
                  {hits.length} hit{hits.length !== 1 ? `s` : ``} from{` `}
                  {scannedCount.toLocaleString()} scanned
                  {promotedCount > 0 && (
                    <>
                      <span className="mx-2 text-slate-300">|</span>
                      <span className="text-emerald-600 font-medium">
                        {promotedCount} promoted
                      </span>
                    </>
                  )}
                </div>
              )}
              <button
                onClick={startScan}
                className="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-brand-violet to-brand-fuchsia rounded-lg hover:opacity-90 transition-opacity"
              >
                {scannedCount > 0 ? `Restart Scan` : `Start Scan`}
              </button>
            </>
          )}
        </div>
      </div>

      {scanning && (
        <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
          <div
            className="bg-gradient-to-r from-brand-violet to-brand-fuchsia h-full rounded-full transition-all duration-300"
            style={{ width: `${(scannedCount / Math.max(apps.length, 1)) * 100}%` }}
          />
        </div>
      )}

      {activeHits.length > 0 && (
        <div className="space-y-3">
          {activeHits.map((hit) => (
            <div
              key={hit.app.bundleId}
              className="bg-white rounded-xl border border-slate-200/80 shadow-sm shadow-slate-200/50 p-4"
            >
              <div className="flex items-start gap-4">
                {hit.iconUrl && (
                  <img
                    src={hit.iconUrl}
                    alt=""
                    className="w-10 h-10 rounded-lg flex-shrink-0 mt-0.5"
                  />
                )}
                <div className="flex-1 min-w-0 space-y-2">
                  <div className="flex items-center gap-2 flex-wrap">
                    <code className="text-xs text-slate-500 font-mono">
                      {hit.app.bundleId}
                    </code>
                    <span className="text-xs text-slate-400">
                      {hit.app.count.toLocaleString()} requests
                    </span>
                    {hit.primaryGenre && (
                      <span className="text-xs text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded">
                        {hit.primaryGenre}
                      </span>
                    )}
                    <span className="text-xs text-slate-400">{hit.developer}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <input
                      type="text"
                      value={hit.editedName}
                      onChange={(e) => {
                        const name = e.target.value;
                        updateHit(hit.app.bundleId, {
                          editedName: name,
                          slug: toSlug(name),
                        });
                      }}
                      className="w-[65%] px-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet"
                    />
                    <input
                      type="text"
                      value={hit.slug}
                      onChange={(e) =>
                        updateHit(hit.app.bundleId, { slug: e.target.value })
                      }
                      className="w-[35%] px-3 py-1.5 text-sm font-mono text-slate-500 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet"
                    />
                    <select
                      value={hit.categoryId}
                      onChange={(e) =>
                        updateHit(hit.app.bundleId, { categoryId: e.target.value })
                      }
                      className="px-2 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet bg-white text-slate-600 max-w-[160px]"
                    >
                      <option value="">(no category)</option>
                      {CATEGORIES.map((cat) => (
                        <option key={cat.id} value={cat.slug}>
                          {cat.name}
                        </option>
                      ))}
                    </select>
                    <button
                      onClick={() => promoteHit(hit)}
                      disabled={hit.promoting}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-white bg-gradient-to-r from-brand-violet to-brand-fuchsia rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50 flex-shrink-0"
                    >
                      {hit.promoting && <LoadingSpinner className="w-3.5 h-3.5" />}
                      Promote
                    </button>
                  </div>
                  {hit.itunesName !== hit.editedName && (
                    <p className="text-xs text-slate-400">iTunes: {hit.itunesName}</p>
                  )}
                  {hit.error && <p className="text-xs text-red-500">{hit.error}</p>}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {promotedCount > 0 && (
        <div className="bg-emerald-50 border border-emerald-200/50 rounded-xl px-4 py-3">
          <div className="flex items-center gap-2 text-sm text-emerald-700">
            <CheckIcon className="w-4 h-4" />
            <span>
              {promotedCount} app{promotedCount !== 1 ? `s` : ``} promoted this session
            </span>
          </div>
        </div>
      )}
    </div>
  );
};

export default AppNamingScan;
