import React, { useEffect, useState } from 'react';
import { useLocation, useNavigate, useParams } from 'react-router-dom';
import type { T } from '@shared/pairql/admin';
import client from '../api/client';
import { ExternalLinkIcon, LoadingSpinner } from '../components/Icons';

type UnidentifiedApp = T.GetUnidentifiedApps.Output[`apps`][number];
type IdentifiedApp = T.GetIdentifiedAppsForAdmin.Output[number];
type Category = NonNullable<IdentifiedApp[`category`]>;

interface LocationState {
  app: UnidentifiedApp;
  identifiedApps: IdentifiedApp[];
}

const ITUNES_GENRE_TO_SLUG: Record<string, string> = {
  Games: `games`,
  'Social Networking': `social-media`,
  Utilities: `utils`,
  'Developer Tools': `programming`,
};

interface ItunesResult {
  name: string;
  developer: string;
  iconUrl: string;
  primaryGenre: string;
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

function companySegment(bundleId: string): string | null {
  const parts = normalizedBundleId(bundleId).split(`.`);
  return parts.length >= 2 ? (parts[1] ?? null) : null;
}

function sharedSegmentCount(a: string, b: string): number {
  const pa = normalizedBundleId(a).split(`.`);
  const pb = normalizedBundleId(b).split(`.`);
  let count = 0;
  for (let i = 0; i < Math.min(pa.length, pb.length); i++) {
    if (pa[i] === pb[i]) count++;
    else break;
  }
  return count;
}

function findPossibleMatches(
  app: UnidentifiedApp,
  identifiedApps: IdentifiedApp[],
): IdentifiedApp[] {
  const appCompany = companySegment(app.bundleId);
  const appNameHint = (app.localizedName ?? app.bundleName ?? ``).toLowerCase();
  const matches: Array<{ app: IdentifiedApp; score: number }> = [];
  for (const identified of identifiedApps) {
    const idName = identified.name.toLowerCase();
    const byDomain =
      appCompany !== null &&
      appCompany.length > 2 &&
      identified.bundleIds.some((b) => companySegment(b.bundleId) === appCompany);
    const byName =
      appNameHint.length > 2 &&
      (appNameHint.includes(idName) || idName.includes(appNameHint));
    if (byDomain || byName) {
      const score = Math.max(
        0,
        ...identified.bundleIds.map((b) => sharedSegmentCount(app.bundleId, b.bundleId)),
      );
      matches.push({ app: identified, score });
    }
  }
  return matches.sort((a, b) => b.score - a.score).map((m) => m.app);
}

function toSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, `-`)
    .replace(/^-|-$/g, ``);
}

const AppNamingDetail: React.FC = () => {
  const navigate = useNavigate();
  const { bundleId: encodedBundleId } = useParams<{ bundleId: string }>();
  const location = useLocation();
  const state = location.state as LocationState | null;

  const app = state?.app ?? null;
  const [identifiedApps, setIdentifiedApps] = useState<IdentifiedApp[]>(
    state?.identifiedApps ?? [],
  );
  const [idAppsLoading, setIdAppsLoading] = useState(identifiedApps.length === 0);

  useEffect(() => {
    if (identifiedApps.length === 0) {
      client.getIdentifiedAppsForAdmin(undefined).then((result) => {
        if (!result.isError && result.value) setIdentifiedApps(result.value);
        setIdAppsLoading(false);
      });
    }
  }, [identifiedApps.length]);

  const [itunesResult, setItunesResult] = useState<ItunesResult | null>(null);
  const [itunesLoading, setItunesLoading] = useState(false);
  const [itunesError, setItunesError] = useState<string | null>(null);

  const [existingSearch, setExistingSearch] = useState(``);
  const [selectedExistingId, setSelectedExistingId] = useState<string | null>(null);

  const [formName, setFormName] = useState(app?.localizedName ?? app?.bundleName ?? ``);
  const [formSlug, setFormSlug] = useState(
    toSlug(app?.localizedName ?? app?.bundleName ?? ``),
  );
  const [formCategoryId, setFormCategoryId] = useState(``);
  const [formLaunchable, setFormLaunchable] = useState(app?.launchable ?? false);

  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);

  const bundleId = encodedBundleId ? decodeURIComponent(encodedBundleId) : ``;

  const possibleMatches = React.useMemo(
    () => (app ? findPossibleMatches(app, identifiedApps) : []),
    [app, identifiedApps],
  );

  const categories = React.useMemo<Category[]>(() => {
    const seen = new Map<string, Category>();
    for (const a of identifiedApps) {
      if (a.category) seen.set(a.category.id, a.category);
    }
    return Array.from(seen.values()).sort((a, b) => a.name.localeCompare(b.name));
  }, [identifiedApps]);

  const filteredExisting = React.useMemo(() => {
    const q = existingSearch.toLowerCase().trim();
    if (!q) return identifiedApps;
    return identifiedApps.filter(
      (a) => a.name.toLowerCase().includes(q) || a.slug.includes(q),
    );
  }, [identifiedApps, existingSearch]);

  const selectedExisting = React.useMemo(
    () => identifiedApps.find((a) => a.id === selectedExistingId) ?? null,
    [identifiedApps, selectedExistingId],
  );

  useEffect(() => {
    handleItunesLookup();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleItunesLookup = async (): Promise<void> => {
    if (!bundleId) return;
    setItunesLoading(true);
    setItunesError(null);
    setItunesResult(null);
    const stripped = normalizedBundleId(bundleId);
    try {
      const resp = await fetch(
        `https://itunes.apple.com/lookup?bundleId=${encodeURIComponent(stripped)}`,
      );
      const data = await resp.json();
      if (data.resultCount > 0) {
        const r = data.results[0];
        const primaryGenre: string = r.primaryGenreName ?? ``;
        const result: ItunesResult = {
          name: r.trackName ?? r.collectionName ?? stripped,
          developer: r.sellerName ?? r.artistName ?? ``,
          iconUrl: r.artworkUrl60 ?? ``,
          primaryGenre,
        };
        setItunesResult(result);
        setFormName(result.name);
        setFormSlug(toSlug(result.name));
        const suggestedSlug = ITUNES_GENRE_TO_SLUG[primaryGenre];
        if (suggestedSlug) {
          const match = categories.find((c) => c.slug === suggestedSlug);
          if (match) setFormCategoryId(match.id);
        }
      } else {
        setItunesError(`No App Store result found for "${stripped}"`);
      }
    } catch {
      setItunesError(`iTunes lookup failed`);
    }
    setItunesLoading(false);
  };

  const handleSubmit = async (): Promise<void> => {
    if (!app) return;
    setSubmitting(true);
    setSubmitError(null);

    let input: T.PromoteApp.Input;
    if (selectedExistingId) {
      input = { bundleId: app.bundleId, existingAppId: selectedExistingId };
    } else {
      if (!formName.trim() || !formSlug.trim()) {
        setSubmitError(`Name and slug are required`);
        setSubmitting(false);
        return;
      }
      input = {
        bundleId: app.bundleId,
        newApp: {
          name: formName.trim(),
          slug: formSlug.trim(),
          categoryId: formCategoryId || undefined,
          launchable: formLaunchable,
        },
      };
    }

    const result = await client.promoteApp(input);
    if (result.isError) {
      setSubmitError(
        result.error?.userMessage ?? result.error?.debugMessage ?? `Promote failed`,
      );
      setSubmitting(false);
      return;
    }

    navigate(`/app-naming`);
  };

  if (!app) {
    return (
      <div className="pt-4 animate-fade-in">
        <p className="text-slate-500 text-sm">
          App not found.{` `}
          <button
            onClick={() => navigate(`/app-naming`)}
            className="text-brand-violet hover:underline"
          >
            Back to list
          </button>
        </p>
      </div>
    );
  }

  return (
    <div className="animate-fade-in pt-4 space-y-4">
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate(`/app-naming`)}
          className="flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors"
        >
          ← Back
        </button>
        <h1 className="text-2xl font-display font-semibold text-slate-900">
          Promote App
        </h1>
      </div>

      <div className="flex gap-6 items-start">
        <div className="w-1/2 bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden flex flex-col">
          <div className="px-5 py-4 border-b border-slate-100">
            <h2 className="font-display font-semibold text-slate-900 text-sm">
              {possibleMatches.length > 0
                ? `${possibleMatches.length} possible match${possibleMatches.length > 1 ? `es` : ``}`
                : `Existing Apps`}
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              {possibleMatches.length > 0
                ? `Select one to link this bundle ID, or search below`
                : `Search to find an app to link this bundle ID to`}
            </p>
          </div>

          <div className="p-4 space-y-3 flex-1 overflow-y-auto">
            {idAppsLoading ? (
              <div className="flex justify-center py-8">
                <LoadingSpinner className="w-5 h-5 text-slate-300" />
              </div>
            ) : (
              <>
                {possibleMatches.length > 0 && (
                  <div className="space-y-2">
                    {possibleMatches.map((match) => (
                      <button
                        key={match.id}
                        onClick={() =>
                          setSelectedExistingId(
                            selectedExistingId === match.id ? null : match.id,
                          )
                        }
                        className={`w-full text-left px-3 py-2.5 rounded-xl border-2 transition-colors ${
                          selectedExistingId === match.id
                            ? `border-brand-violet bg-brand-50`
                            : `border-amber-200 bg-amber-50 hover:border-amber-400`
                        }`}
                      >
                        <span className="text-sm font-medium text-slate-800">
                          {match.name}
                        </span>
                        {match.category && (
                          <span className="ml-2 text-xs text-slate-400">
                            {match.category.name}
                          </span>
                        )}
                        {match.bundleIds.length > 0 && (
                          <p className="text-xs text-slate-400 font-mono mt-0.5">
                            {match.bundleIds.map((b) => b.bundleId).join(`, `)}
                          </p>
                        )}
                      </button>
                    ))}
                    <div className="border-t border-slate-100 pt-3">
                      <p className="text-xs text-slate-400 mb-2">
                        Or search all identified apps
                      </p>
                    </div>
                  </div>
                )}

                <input
                  type="text"
                  value={existingSearch}
                  onChange={(e) => setExistingSearch(e.target.value)}
                  placeholder="Search identified apps..."
                  className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet"
                />

                <div className="max-h-72 overflow-y-auto border border-slate-200 rounded-lg divide-y divide-slate-100">
                  {filteredExisting.map((a) => (
                    <button
                      key={a.id}
                      onClick={() =>
                        setSelectedExistingId(selectedExistingId === a.id ? null : a.id)
                      }
                      className={`w-full text-left px-3 py-2.5 text-sm transition-colors ${
                        selectedExistingId === a.id
                          ? `bg-brand-50 text-brand-violet`
                          : `hover:bg-slate-50 text-slate-700`
                      }`}
                    >
                      <span className="font-medium">{a.name}</span>
                      <span className="text-xs text-slate-400 ml-2 font-mono">
                        {a.slug}
                      </span>
                      {a.bundleIds.length > 0 && (
                        <p className="text-xs text-slate-400 mt-0.5 font-mono">
                          {a.bundleIds.map((b) => b.bundleId).join(`, `)}
                        </p>
                      )}
                    </button>
                  ))}
                  {filteredExisting.length === 0 && (
                    <p className="px-3 py-4 text-sm text-slate-400 text-center">
                      No apps found
                    </p>
                  )}
                </div>
              </>
            )}
          </div>
        </div>

        <div className="w-1/2 bg-white rounded-2xl border border-slate-200/80 shadow-sm shadow-slate-200/50 overflow-hidden">
          <div className="px-5 py-4 border-b border-slate-100">
            <h2 className="font-display font-semibold text-slate-900 text-sm">
              {selectedExisting ? `Link to ${selectedExisting.name}` : `New App`}
            </h2>
          </div>

          <div className="p-5 space-y-5">
            <div>
              <div className="flex items-center gap-2">
                <code className="font-mono text-sm text-slate-800 bg-slate-100 px-2 py-1 rounded flex-1 break-all">
                  {app.bundleId}
                </code>
                <button
                  onClick={() => navigator.clipboard.writeText(app.bundleId)}
                  className="text-xs text-slate-400 hover:text-slate-600 bg-slate-100 hover:bg-slate-200 px-2 py-1.5 rounded transition-colors"
                >
                  Copy
                </button>
              </div>
              {(app.bundleName ?? app.localizedName) && (
                <p className="mt-1.5 text-xs text-slate-400">
                  {[app.bundleName, app.localizedName].filter(Boolean).join(` / `)}
                </p>
              )}
              <p className="mt-1 text-xs text-slate-400">
                {app.count.toLocaleString()} requests
              </p>
            </div>

            <div>
              <div className="flex items-center gap-2">
                <button
                  onClick={handleItunesLookup}
                  disabled={itunesLoading}
                  className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-sky-600 hover:text-sky-700 bg-sky-50 hover:bg-sky-100 rounded-lg transition-all disabled:opacity-50"
                >
                  {itunesLoading && <LoadingSpinner className="w-3.5 h-3.5" />}
                  Look up on App Store
                </button>
                <a
                  href={`https://www.google.com/search?q="${encodeURIComponent(normalizedBundleId(app.bundleId))}" bundle ID`}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 hover:text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-all"
                >
                  Google This Bundle ID
                  <ExternalLinkIcon className="w-3.5 h-3.5" />
                </a>
              </div>
              {itunesError && <p className="mt-2 text-xs text-red-500">{itunesError}</p>}
              {itunesResult && (
                <div className="mt-3 flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
                  {itunesResult.iconUrl && (
                    <img
                      src={itunesResult.iconUrl}
                      alt=""
                      className="w-10 h-10 rounded-lg"
                    />
                  )}
                  <div>
                    <p className="font-medium text-slate-900 text-sm">
                      {itunesResult.name}
                    </p>
                    <p className="text-xs text-slate-500">{itunesResult.developer}</p>
                    {itunesResult.primaryGenre && (
                      <p className="text-xs text-slate-400 mt-0.5">
                        {itunesResult.primaryGenre}
                        {ITUNES_GENRE_TO_SLUG[itunesResult.primaryGenre] && (
                          <span className="ml-1 text-emerald-600">
                            → category auto-selected
                          </span>
                        )}
                      </p>
                    )}
                  </div>
                </div>
              )}
            </div>

            {selectedExisting ? (
              <div className="rounded-xl border border-brand-violet/20 bg-brand-50 px-4 py-3 space-y-1">
                <p className="text-sm font-medium text-slate-800">
                  Link to{` `}
                  <span className="text-brand-violet">{selectedExisting.name}</span>
                </p>
                {selectedExisting.bundleIds.length > 0 && (
                  <p className="text-xs text-slate-400 font-mono">
                    Existing:{` `}
                    {selectedExisting.bundleIds.map((b) => b.bundleId).join(`, `)}
                  </p>
                )}
                <button
                  onClick={() => setSelectedExistingId(null)}
                  className="text-xs text-slate-400 hover:text-slate-600 transition-colors"
                >
                  Clear selection → create new app instead
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1">
                    Name
                  </label>
                  <input
                    type="text"
                    value={formName}
                    onChange={(e) => {
                      setFormName(e.target.value);
                      if (!formSlug || formSlug === toSlug(formName)) {
                        setFormSlug(toSlug(e.target.value));
                      }
                    }}
                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet"
                    placeholder="e.g. Roblox"
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1">
                    Slug
                  </label>
                  <input
                    type="text"
                    value={formSlug}
                    onChange={(e) => setFormSlug(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet font-mono"
                    placeholder={formName ? toSlug(formName) : `e.g. roblox`}
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-600 mb-1">
                    Category
                  </label>
                  <select
                    value={formCategoryId}
                    onChange={(e) => setFormCategoryId(e.target.value)}
                    className="w-full px-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-brand-violet/30 focus:border-brand-violet bg-white"
                  >
                    <option value="">(none)</option>
                    {categories.map((cat) => (
                      <option key={cat.id} value={cat.id}>
                        {cat.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex items-center gap-3">
                  <label className="text-xs font-medium text-slate-600">Launchable</label>
                  <button
                    type="button"
                    onClick={() => setFormLaunchable((v) => !v)}
                    className={`relative inline-flex h-5 w-9 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                      formLaunchable ? `bg-brand-violet` : `bg-slate-200`
                    }`}
                  >
                    <span
                      className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition-transform duration-200 ease-in-out ${
                        formLaunchable ? `translate-x-4` : `translate-x-0`
                      }`}
                    />
                  </button>
                </div>
              </div>
            )}

            {submitError && (
              <p className="text-sm text-red-500 bg-red-50 px-3 py-2 rounded-lg">
                {submitError}
              </p>
            )}

            <button
              onClick={handleSubmit}
              disabled={submitting}
              className="w-full py-2.5 px-4 bg-gradient-to-r from-brand-violet to-brand-fuchsia text-white text-sm font-medium rounded-lg hover:opacity-90 transition-opacity disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {submitting && <LoadingSpinner className="w-4 h-4" />}
              {selectedExisting ? `Link & Promote` : `Create & Promote`}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AppNamingDetail;
