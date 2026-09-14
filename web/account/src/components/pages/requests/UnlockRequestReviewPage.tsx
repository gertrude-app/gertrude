import {
  Banner,
  Button,
  ConfirmationDialog,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  PageHeading,
  Text,
  Textarea,
  VStack,
  inflect,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  ChevronDownIcon,
  GlobeIcon,
  KeyRoundIcon,
  RotateCcwIcon,
  ShieldXIcon,
} from 'lucide-react';
import React from 'react';
import type {
  UnlockAppEntry,
  UnlockDomainGroup,
  UnlockReviewEntry,
} from '#/lib/unlockRequests';
import type {
  DecideUnlockRequests,
  GetPersonUnlockRequests,
} from '@shared/pairql/src/account';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import UnlockRequestCard from '#/components/requests/UnlockRequestCard';
import {
  buildUnlockReview,
  decidedRequestCount,
  decisionsForSubmission,
  denyAllDecisions,
  totalRequestCount,
} from '#/lib/unlockRequests';

interface Props {
  data: GetPersonUnlockRequests.Output;
  saving: boolean;
  appIconUrl: (hash: string) => string;
  onSubmit: (
    decisions: DecideUnlockRequests.Input[`decisions`],
    responseComment?: string,
  ) => void;
  onRefresh: () => void;
}

const appRequestCount = (entry: UnlockAppEntry): number =>
  entry.groups.reduce((sum, group) => sum + group.requestIds.length, 0);

type AppBulkDecision = `allow` | `deny` | `undecided`;

const AppRequestSection: React.FC<{
  entry: UnlockAppEntry;
  keychainOptions: GetPersonUnlockRequests.Output[`keychains`];
  iconUrl?: string;
  onChange: (entry: UnlockAppEntry) => void;
}> = ({ entry, keychainOptions, iconUrl, onChange }) => {
  const applyBulkDecision = (decision: AppBulkDecision): void => {
    const choice =
      decision === `allow`
        ? (`requestedAddresses` as const)
        : decision === `deny`
          ? (`deny` as const)
          : (`perAddress` as const);
    onChange({
      ...entry,
      choice,
      groups: entry.groups.map((group) => ({ ...group, decision })),
    });
  };

  const toggleUnrestricted = (): void => {
    onChange({
      ...entry,
      choice: entry.choice === `unrestricted` ? `perAddress` : `unrestricted`,
    });
  };

  const updateGroup = (updated: UnlockDomainGroup): void => {
    onChange({
      ...entry,
      choice: `perAddress`,
      groups: entry.groups.map((group) => (group.id === updated.id ? updated : group)),
    });
  };

  const decisionCounts = entry.groups.reduce(
    (counts, group) => {
      counts[group.decision] += group.requestIds.length;
      return counts;
    },
    { allow: 0, deny: 0, undecided: 0 },
  );
  const decisionSummary =
    entry.choice === `unrestricted`
      ? `Full internet access selected`
      : [
          decisionCounts.allow > 0 ? `${decisionCounts.allow} allowed` : undefined,
          decisionCounts.deny > 0 ? `${decisionCounts.deny} denied` : undefined,
          decisionCounts.undecided > 0
            ? `${decisionCounts.undecided} undecided`
            : undefined,
        ]
          .filter((part): part is string => part !== undefined)
          .join(` · `);
  const unknownApp = entry.name === `Unknown app`;
  const unrestricted = entry.choice === `unrestricted`;
  const allAllowed =
    !unrestricted && entry.groups.every((group) => group.decision === `allow`);
  const allDenied =
    !unrestricted && entry.groups.every((group) => group.decision === `deny`);
  const allUndecided =
    !unrestricted && entry.groups.every((group) => group.decision === `undecided`);

  return (
    <section className="flex flex-col gap-4" aria-label={`${entry.name} requests`}>
      <div className="relative flex flex-col gap-3 rounded-xl border border-stone-200 bg-stone-100/70 p-3 @2xl/main:flex-row @2xl/main:items-center @2xl/main:justify-between">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute top-1/2 -bottom-[18px] hidden rounded-tl-xl border-t-2 border-l-2 border-stone-300 @3xl/main:-left-[17px] @3xl/main:block @3xl/main:w-[17px]"
        />
        <HStack align="center" gap={2.5} className="min-w-0">
          {iconUrl ? (
            <img src={iconUrl} alt="" className="h-10 w-10 shrink-0 object-contain" />
          ) : (
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg border border-stone-200 bg-white text-sm font-semibold text-stone-500">
              {entry.name.slice(0, 1)}
            </span>
          )}
          <VStack gap={0.5} className="min-w-0">
            <HStack wrap gap={1.5}>
              <Text as="h2" variant="bodyLargeStrong">
                {entry.name}
              </Text>
              <Text
                variant="caption"
                className="min-w-5 shrink-0 rounded-full bg-stone-200/70 px-1.5 text-center font-medium leading-5 tabular-nums !text-stone-600"
              >
                {appRequestCount(entry)}
              </Text>
            </HStack>
            {unknownApp && (
              <Text variant="captionMuted" truncate>
                {entry.bundleId ?? `Unidentified application`}
              </Text>
            )}
            <Text variant="captionSubtleStrong">{decisionSummary}</Text>
          </VStack>
        </HStack>

        <div className="flex shrink-0 flex-wrap items-center gap-2 @2xl/main:justify-end">
          <DropdownMenu
            contentClassName="w-72"
            trigger={
              <Button
                type="button"
                size="small"
                icon={ChevronDownIcon}
                iconPosition="right"
                onClick={() => {}}
              >
                Respond to all
              </Button>
            }
          >
            <DropdownMenuItem
              title="Allow all requested addresses"
              description="Create keys for every address requested by this app."
              icon={KeyRoundIcon}
              disabled={allAllowed}
              onSelect={() => applyBulkDecision(`allow`)}
            />
            <DropdownMenuItem
              title="Deny all requests"
              description="Deny every pending request from this app."
              icon={ShieldXIcon}
              destructive
              disabled={allDenied}
              onSelect={() => applyBulkDecision(`deny`)}
            />
            <DropdownMenuItem
              title="Reset all to undecided"
              description="Clear every address decision for this app."
              icon={RotateCcwIcon}
              disabled={allUndecided}
              onSelect={() => applyBulkDecision(`undecided`)}
            />
          </DropdownMenu>
          <Button
            type="button"
            size="small"
            variant={unrestricted ? `selected` : `ghost`}
            icon={GlobeIcon}
            aria-pressed={unrestricted}
            onClick={toggleUnrestricted}
          >
            Grant {entry.name} full internet access
          </Button>
        </div>
      </div>

      {unrestricted && (
        <div className="relative">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute -top-[17px] -bottom-4 left-3 border-l-2 border-stone-300 @3xl/main:-top-4 @3xl/main:-left-4"
          />
          <Banner
            variant={unknownApp ? `error` : `warning`}
            className="rounded-lg py-2 [&>svg]:h-4 [&>svg]:w-4"
          >
            <strong>
              {unknownApp
                ? `Gertrude could not identify this app.`
                : `This gives the app broad access.`}
            </strong>
            {` `}
            {unknownApp
              ? `Only grant full internet access if you recognize the bundle identifier above and trust the app.`
              : `It can reach sites and services that were not included in these requests.`}
            {` `}
            Turn this off to respond to individual addresses.
          </Banner>
        </div>
      )}

      <div className="relative pb-5">
        <div
          aria-hidden="true"
          className={cx(
            `pointer-events-none absolute bottom-0 left-3 w-15 rounded-bl-[32px] border-b-2 border-l-2 border-stone-300 @3xl/main:top-0 @3xl/main:-left-4`,
            unrestricted ? `top-0` : `-top-[17px]`,
          )}
        />
        <fieldset
          disabled={unrestricted}
          className={cx(
            `flex min-w-0 flex-col gap-6 pl-7 transition-opacity @3xl/main:pl-0`,
            unrestricted && `opacity-50`,
          )}
        >
          {entry.groups.map((group) => (
            <UnlockRequestCard
              key={group.id}
              group={group}
              appName={entry.name}
              keychainOptions={keychainOptions}
              onChange={updateGroup}
            />
          ))}
        </fieldset>
      </div>
    </section>
  );
};

const UnlockRequestReviewPage: React.FC<Props> = ({
  data,
  saving,
  appIconUrl,
  onSubmit,
  onRefresh,
}) => {
  const defaultKeychainId = data.keychains[0]?.id;
  const [entries, setEntries] = React.useState<UnlockReviewEntry[]>(() =>
    buildUnlockReview(data.requests, defaultKeychainId),
  );
  const [denyAllResponseComment, setDenyAllResponseComment] = React.useState(``);

  const decidedCount = decidedRequestCount(entries);
  const totalCount = totalRequestCount(entries);
  const decisions = decisionsForSubmission(entries);
  const recommendedDenyCount = entries.reduce((sum, entry) => {
    if (
      entry.kind === `app` &&
      (entry.choice === `requestedAddresses` || entry.choice === `unrestricted`)
    ) {
      return sum;
    }
    const groups = entry.kind === `web` ? [entry.group] : entry.groups;
    return (
      sum +
      groups.reduce(
        (groupSum, group) =>
          groupSum +
          (group.risk?.level === `strongWarning` && group.decision === `deny`
            ? group.requestIds.length
            : 0),
        0,
      )
    );
  }, 0);

  const updateEntry = (updated: UnlockReviewEntry): void => {
    setEntries((current) =>
      current.map((entry) => (entry.id === updated.id ? updated : entry)),
    );
  };

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={`Review ${data.personName}'s requests`}
          subtitle={`${totalCount} pending ${inflect(`request`, totalCount)}`}
          breadcrumbs={[{ text: `Requests`, href: `/requests/unlock` }]}
          buttons={[
            {
              text: `Refresh`,
              onClick: onRefresh,
            },
          ]}
        />
      }
    >
      <div className="flex w-full flex-col gap-3 pb-28 @lg/main:pb-24">
        {recommendedDenyCount > 0 && (
          <Banner
            variant="error"
            className="rounded-lg py-2 [&>svg]:h-4 [&>svg]:w-4 [&>div]:text-xs [&>div]:leading-4"
          >
            <strong>Deny was pre-selected</strong> for {recommendedDenyCount}
            {` `}
            higher-risk {inflect(`request`, recommendedDenyCount)}. Review the warning
            before changing it.
          </Banner>
        )}

        <CardContainer className="flex flex-col gap-6">
          {entries.map((entry) =>
            entry.kind === `web` ? (
              <UnlockRequestCard
                key={entry.id}
                group={entry.group}
                keychainOptions={data.keychains}
                onChange={(group) => updateEntry({ ...entry, group })}
              />
            ) : (
              <AppRequestSection
                key={entry.id}
                entry={entry}
                keychainOptions={data.keychains}
                iconUrl={entry.iconHash ? appIconUrl(entry.iconHash) : undefined}
                onChange={updateEntry}
              />
            ),
          )}
        </CardContainer>
      </div>

      <div className="fixed right-0 bottom-0 left-[var(--sidebar-width,0px)] z-20 border-t border-stone-200 bg-white/95 px-3 py-2 shadow-[0_-6px_24px_rgba(28,25,23,0.08)] backdrop-blur">
        <div className="mx-auto flex w-full max-w-[1200px] items-center justify-between gap-2 px-3 @lg/main:px-4 @xl/main:px-8 @3xl/main:px-12">
          <div className="min-w-0 shrink-0">
            <Text variant="bodyStrong" className="whitespace-nowrap">
              <span className="@sm/main:hidden">
                {decidedCount} of {totalCount} decided
              </span>
              <span className="hidden @sm/main:inline">
                {decidedCount} of {totalCount} requests decided
              </span>
            </Text>
            <Text variant="captionMuted" className="hidden @lg/main:block">
              Undecided requests stay in the queue.
            </Text>
          </div>
          <HStack justify="end" gap={2} className="shrink-0">
            <ConfirmationDialog
              confirmationQuestion={`Deny all ${totalCount} requests?`}
              description={
                <VStack gap={4}>
                  <Text variant="bodySubtle">
                    This will deny every pending request shown here. No keys will be
                    created.
                  </Text>
                  <Textarea
                    label="Optional message"
                    placeholder={`For example: Let's talk about this after dinner.`}
                    rows={3}
                    resize="vertical"
                    value={denyAllResponseComment}
                    setValue={setDenyAllResponseComment}
                  />
                </VStack>
              }
              trigger={
                <Button
                  type="button"
                  size="medium"
                  variant="destructive"
                  onClick={() => {}}
                >
                  Deny all
                </Button>
              }
              actions={[
                { text: `Cancel` },
                {
                  text: `Deny all`,
                  variant: `destructive`,
                  disabled: saving,
                  onClick: () =>
                    onSubmit(
                      denyAllDecisions(entries),
                      denyAllResponseComment.trim() || undefined,
                    ),
                },
              ]}
            />
            <Button
              type="button"
              size="medium"
              variant="primary"
              loading={saving}
              disabled={decidedCount === 0}
              onClick={() => onSubmit(decisions)}
            >
              Submit decided
            </Button>
          </HStack>
        </div>
      </div>
    </DashboardPage>
  );
};

export default UnlockRequestReviewPage;
