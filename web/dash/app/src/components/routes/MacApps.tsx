import {
  AddAppsPanel,
  ApiErrorMessage,
  AppSelectionEmptyHint,
  BLOCKED_TILE_THEME,
  BlockedAppCard,
  EnterTransition,
  INTERNET_TILE_THEME,
  Loading,
  PageHeading,
  UnrestrictedAppCard,
} from '@dash/components';
import { Button } from '@shared/components';
import React, { useMemo, useReducer, useState } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import type { BlockedMacApp, SingleAppScope } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';

interface InstalledApp {
  bundleId: string;
  name: string;
  iconUrl?: string;
  identifiedAppSlug?: string;
}

const MacAppsRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const [blockedOpen, setBlockedOpen] = useState(false);
  const [internetOpen, setInternetOpen] = useState(false);
  const [recent, setRecent] = useState<Set<string>>(new Set());
  const queryKey = Key.child(userId);

  const childQuery = useQuery(queryKey, () => Current.api.getChild(userId), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
  });

  const installedAppsQuery = useQuery(Key.installedMacApps(userId), () =>
    Current.api.getInstalledMacApps(userId),
  );

  const apiBase = Current.env.apiEndpoint();
  const installedApps = useMemo<InstalledApp[]>(
    () =>
      installedAppsQuery.data?.map((app) => ({
        bundleId: app.bundleId,
        name: app.name,
        identifiedAppSlug: app.identifiedAppSlug,
        iconUrl: app.iconHash ? `${apiBase}/app-icon/${app.iconHash}` : undefined,
      })) ?? [],
    [installedAppsQuery.data, apiBase],
  );

  const saveChild = useMutation(
    () => {
      const child = state.child;
      if (!child) throw new Error(`No child loaded`);
      return Current.api.saveMacappApps({
        id: child.draft.id,
        blockedApps: child.draft.blockedApps ?? [],
        unrestrictedApps: child.draft.unrestrictedApps ?? [],
      });
    },
    {
      onSuccess: () => dispatch({ type: `childSaved` }),
      invalidating: [queryKey],
      toast: `save:user`,
    },
  );

  if (childQuery.isError) {
    return <ApiErrorMessage error={childQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  if (state.child.original.computers.length === 0) {
    return <Navigate to=".." replace relative="path" />;
  }

  const { draft } = state.child;
  const blockedApps = draft.blockedApps ?? [];
  const unrestrictedApps = draft.unrestrictedApps ?? [];
  const publicUnrestrictedApps = draft.publicUnrestrictedApps ?? [];
  const saveDisabled = !isDirty(state.child) || saveChild.isPending;

  const grantedScopes = [
    ...unrestrictedApps.map((app) => app.scope),
    ...publicUnrestrictedApps.map((app) => app.scope),
  ];
  const blockedCandidates = installedApps
    .filter((app) => !isBlocked(app, blockedApps))
    .map(toItem);
  const internetCandidates = installedApps
    .filter((app) => !isGranted(app, grantedScopes) && !isAlwaysBlocked(app, blockedApps))
    .map(toItem);

  return (
    <div className="max-w-3xl">
      <Link
        to=".."
        relative="path"
        className="inline-flex items-center text-sm text-violet-600 hover:underline mb-4"
      >
        <i className="fa-solid fa-arrow-left mr-1.5" />
        {draft.name}&rsquo;s Mac
      </Link>
      <PageHeading icon="layer-group">Apps</PageHeading>
      <p className="text-slate-500 mt-2 ml-[60px]">
        Choose which apps {draft.name} can&rsquo;t use, and which ones get unrestricted
        internet.
      </p>

      <section className="mt-10">
        <h2 className="text-lg font-bold text-slate-700">Blocked apps</h2>
        <p className="text-sm text-slate-400 mt-1">
          These apps can&rsquo;t open at all. Add a schedule to only block them at certain
          times.
        </p>

        {blockedApps.length === 0 && !blockedOpen ? (
          <AppSelectionEmptyHint
            text="Nothing is blocked yet."
            cta="Pick apps to block"
            onClick={() => setBlockedOpen(true)}
          />
        ) : (
          <div className="flex flex-col gap-1.5 mt-3">
            {blockedApps.map((app) => {
              const resolved = resolveByIdentifier(app.identifier, installedApps);
              return (
                <EnterTransition key={app.id} animate={recent.has(app.identifier)}>
                  <BlockedAppCard
                    app={app}
                    resolvedName={resolved?.name}
                    iconUrl={resolved?.iconUrl}
                    setSchedule={(schedule) =>
                      dispatch({ type: `setBlockedAppSchedule`, id: app.id, schedule })
                    }
                    onDelete={() => dispatch({ type: `removeBlockedApp`, id: app.id })}
                  />
                </EnterTransition>
              );
            })}
          </div>
        )}

        {blockedApps.length > 0 && !blockedOpen && (
          <div className="flex justify-end mt-3">
            <Button
              type="button"
              size="small"
              color="secondary"
              onClick={() => setBlockedOpen(true)}
            >
              <i className="fa-solid fa-plus mr-1.5" />
              Add apps to block
            </Button>
          </div>
        )}

        <AddAppsPanel
          open={blockedOpen}
          apps={blockedCandidates}
          theme={BLOCKED_TILE_THEME}
          commitLabel={(n) =>
            n === 0 ? `Block apps` : `Block ${n} app${n === 1 ? `` : `s`}`
          }
          onCommit={(ids) => {
            dispatch({ type: `addBlockedApps`, identifiers: ids });
            setBlockedOpen(false);
            setRecent(new Set(ids));
          }}
          onCancel={() => setBlockedOpen(false)}
        />
      </section>

      <section className="mt-12">
        <h2 className="text-lg font-bold text-slate-700">Unrestricted internet apps</h2>
        <p className="text-sm text-slate-400 mt-1">
          By default apps can&rsquo;t reach the internet. These apps are granted full,
          unrestricted access.
        </p>

        {unrestrictedApps.length === 0 &&
        publicUnrestrictedApps.length === 0 &&
        !internetOpen ? (
          <AppSelectionEmptyHint
            text="No apps have unrestricted internet yet."
            cta="Pick apps to grant internet"
            onClick={() => setInternetOpen(true)}
          />
        ) : (
          <div className="flex flex-col gap-1.5 mt-3">
            {unrestrictedApps.map((app) => {
              const resolved = resolveByScope(app.scope, installedApps);
              return (
                <EnterTransition key={app.id} animate={recent.has(scopeKey(app.scope))}>
                  <UnrestrictedAppCard
                    name={resolved?.name ?? scopeLabel(app.scope)}
                    iconUrl={resolved?.iconUrl}
                    blocked={resolved ? isAlwaysBlocked(resolved, blockedApps) : false}
                    onDelete={() =>
                      dispatch({ type: `removeUnrestrictedApp`, id: app.id })
                    }
                  />
                </EnterTransition>
              );
            })}
            {publicUnrestrictedApps.map((app, index) => {
              const resolved = resolveByScope(app.scope, installedApps);
              return (
                <UnrestrictedAppCard
                  key={`public-${app.keychainId}-${scopeKey(app.scope)}-${index}`}
                  name={resolved?.name ?? scopeLabel(app.scope)}
                  iconUrl={resolved?.iconUrl}
                  blocked={resolved ? isAlwaysBlocked(resolved, blockedApps) : false}
                  keychainName={app.keychainName}
                />
              );
            })}
          </div>
        )}

        {(unrestrictedApps.length > 0 || publicUnrestrictedApps.length > 0) &&
          !internetOpen && (
            <div className="flex justify-end mt-3">
              <Button
                type="button"
                size="small"
                color="secondary"
                onClick={() => setInternetOpen(true)}
              >
                <i className="fa-solid fa-plus mr-1.5" />
                Grant internet to apps
              </Button>
            </div>
          )}

        <AddAppsPanel
          open={internetOpen}
          apps={internetCandidates}
          theme={INTERNET_TILE_THEME}
          commitLabel={(n) =>
            n === 0 ? `Grant internet` : `Grant internet to ${n} app${n === 1 ? `` : `s`}`
          }
          onCommit={(ids) => {
            const scopes = ids
              .map((id) => installedApps.find((app) => app.bundleId === id))
              .filter((app): app is InstalledApp => app !== undefined)
              .map(deriveScope);
            dispatch({ type: `addUnrestrictedApps`, scopes });
            setInternetOpen(false);
            setRecent(new Set(scopes.map(scopeKey)));
          }}
          onCancel={() => setInternetOpen(false)}
        />
      </section>

      <div className="flex mt-12 pt-8 border-t-2 border-slate-200 justify-end">
        <Button
          type="button"
          disabled={saveDisabled}
          onClick={() => saveChild.mutate(undefined)}
          color="primary"
        >
          Save settings
        </Button>
      </div>
    </div>
  );
};

export default MacAppsRoute;

function toItem(app: InstalledApp): { id: string; name: string; iconUrl?: string } {
  return { id: app.bundleId, name: app.name, iconUrl: app.iconUrl };
}

function deriveScope(app: InstalledApp): SingleAppScope {
  return app.identifiedAppSlug
    ? { type: `identifiedAppSlug`, identifiedAppSlug: app.identifiedAppSlug }
    : { type: `bundleId`, bundleId: app.bundleId };
}

function scopeKey(scope: SingleAppScope): string {
  return scope.type === `identifiedAppSlug`
    ? `slug:${scope.identifiedAppSlug}`
    : `bundle:${scope.bundleId}`;
}

function scopeLabel(scope: SingleAppScope): string {
  return scope.type === `identifiedAppSlug` ? scope.identifiedAppSlug : scope.bundleId;
}

function isGranted(app: InstalledApp, scopes: SingleAppScope[]): boolean {
  return scopes.some((scope) =>
    scope.type === `identifiedAppSlug`
      ? scope.identifiedAppSlug === app.identifiedAppSlug
      : scope.bundleId === app.bundleId,
  );
}

function isBlocked(app: InstalledApp, blockedApps: BlockedMacApp[]): boolean {
  return blockedApps.some((blocked) => matchesIdentifier(blocked.identifier, app));
}

function isAlwaysBlocked(app: InstalledApp, blockedApps: BlockedMacApp[]): boolean {
  return blockedApps.some(
    (blocked) => !blocked.schedule && matchesIdentifier(blocked.identifier, app),
  );
}

function matchesIdentifier(identifier: string, app: InstalledApp): boolean {
  return (
    identifier === app.bundleId || identifier.toLowerCase() === app.name.toLowerCase()
  );
}

function resolveByScope(
  scope: SingleAppScope,
  installedApps: InstalledApp[],
): InstalledApp | undefined {
  return scope.type === `identifiedAppSlug`
    ? installedApps.find((app) => app.identifiedAppSlug === scope.identifiedAppSlug)
    : installedApps.find((app) => app.bundleId === scope.bundleId);
}

function resolveByIdentifier(
  identifier: string,
  installedApps: InstalledApp[],
): InstalledApp | undefined {
  const byBundleId = installedApps.find((app) => app.bundleId === identifier);
  if (byBundleId) return byBundleId;
  const lower = identifier.toLowerCase();
  return installedApps.find((app) => app.name.toLowerCase() === lower);
}
