import {
  Banner,
  Button,
  Card,
  CountBadge,
  DateTimePicker,
  HStack,
  Select,
  Text,
  Textarea,
  Tooltip,
  VStack,
} from '@gertrude/ui';
import { formatDate } from '@shared/datetime';
import cx from 'clsx';
import {
  BanIcon,
  CheckIcon,
  ChevronRightIcon,
  GlobeIcon,
  LayoutGridIcon,
  MonitorIcon,
  SettingsIcon,
} from 'lucide-react';
import React from 'react';
import type { UnlockDomainGroup, UnlockKey, UnlockRowState } from '#/lib/unlockRequests';
import type { SelectOption } from '@gertrude/ui';
import type { AppScope, GetPersonUnlockRequests } from '@shared/pairql/src/account';
import MessageBubble from '#/components/MessageBubble';
import { formatSchedule } from '#/components/utils';
import {
  addressMatchOptions,
  groupAddressMatch,
  keyForUnlockRequest,
  permissionLabel,
  sanitizeRequestedAddress,
  updateGroupDecision,
  updateGroupKeyAddressMatch,
} from '#/lib/unlockRequests';

interface Props {
  group: UnlockDomainGroup;
  keychainOptions: GetPersonUnlockRequests.Output[`keychains`];
  appName?: string;
  rowState?: UnlockRowState;
  defaultSettingsOpen?: boolean;
  defaultMatchOptionsOpen?: boolean;
  onChange: (group: UnlockDomainGroup) => void;
}

type ScopeChoice = `webBrowsers` | `singleApp` | `unrestricted`;

const requestCount = (group: UnlockDomainGroup): number => group.requestIds.length;

const scopeChoice = (key: UnlockKey): ScopeChoice => {
  if (key.scope.type === `webBrowsers`) {
    return `webBrowsers`;
  }
  return key.scope.type === `single` ? `singleApp` : `unrestricted`;
};

const withScope = (
  key: UnlockKey,
  choice: ScopeChoice,
  originalScope: AppScope,
): UnlockKey => {
  const scope: AppScope =
    choice === `webBrowsers`
      ? { type: `webBrowsers` }
      : choice === `unrestricted`
        ? { type: `unrestricted` }
        : originalScope.type === `single`
          ? originalScope
          : key.scope;
  return { ...key, scope };
};

const scopeOptions = (
  appName: string | undefined,
  canSelectApp: boolean,
): Array<SelectOption<ScopeChoice>> => [
  ...(!canSelectApp
    ? [
        {
          value: `webBrowsers` as const,
          label: `Web browsers`,
          description: `Safari, Chrome, Firefox, and other browsers`,
          icon: GlobeIcon,
        },
      ]
    : []),
  ...(canSelectApp
    ? [
        {
          value: `singleApp` as const,
          label: appName ?? `Requested app`,
          description: `Only the app that made this request`,
          icon: MonitorIcon,
        },
      ]
    : []),
  {
    value: `unrestricted`,
    label: `All apps`,
    description: `Every app on assigned Macs`,
    icon: LayoutGridIcon,
  },
];

const DecisionButtons: React.FC<{
  decision: UnlockDomainGroup[`decision`];
  included?: boolean;
  setDecision: (decision: UnlockDomainGroup[`decision`]) => void;
}> = ({ decision, included = false, setDecision }) => (
  <div className="inline-flex shrink-0 flex-col rounded-full border border-stone-200 bg-stone-100 p-0.5">
    {([`deny`, `allow`] as const)
      .filter((choice) => !included || choice === `allow`)
      .map((choice) => {
        const Icon = choice === `deny` ? BanIcon : CheckIcon;
        const selected = included || decision === choice;
        const label = included
          ? `Included in another approval`
          : selected
            ? `Clear decision`
            : choice === `deny`
              ? `Deny request`
              : `Allow request`;
        return (
          <Tooltip key={choice} content={label} side="left">
            <button
              type="button"
              aria-label={label}
              aria-pressed={selected}
              disabled={included}
              onClick={
                included ? undefined : () => setDecision(selected ? `undecided` : choice)
              }
              className={cx(
                `flex h-7 w-7 cursor-pointer items-center justify-center rounded-full border outline-none transition-colors focus-visible:ring-2 focus-visible:ring-violet-300 focus-visible:ring-offset-1 disabled:cursor-default`,
                selected
                  ? choice === `deny`
                    ? `border-stone-300 bg-white text-red-600 shadow-sm`
                    : `border-stone-300 bg-white text-violet-600 shadow-sm`
                  : `border-transparent text-stone-400 hover:bg-stone-200 hover:text-stone-700`,
              )}
            >
              <Icon className="h-4 w-4" />
            </button>
          </Tooltip>
        );
      })}
  </div>
);

const UnlockRequestCard: React.FC<Props> = ({
  group,
  keychainOptions,
  appName,
  rowState,
  defaultSettingsOpen = false,
  defaultMatchOptionsOpen = false,
  onChange,
}) => {
  const [customize, setCustomize] = React.useState(defaultSettingsOpen);
  React.useEffect(() => {
    if (group.decision !== `allow`) setCustomize(false);
  }, [group.decision]);
  const requestedKey = group.requests[0]
    ? keyForUnlockRequest(group.requests[0])
    : group.key;
  const originalScope = React.useRef<AppScope>(requestedKey.scope);
  const matchingOptions = addressMatchOptions(group).map(({ domain, ...option }) => {
    const domainStart = option.label.indexOf(domain);
    return {
      ...option,
      labelContent: (
        <span className="font-normal">
          {option.label.slice(0, domainStart)}
          <code className="inline-block max-w-full rounded-md border-[0.5px] border-stone-200 bg-stone-200/40 px-1.5 py-0.5 font-mono text-[0.9em] font-medium">
            {domain}
          </code>
          {option.label.slice(domainStart + domain.length)}
        </span>
      ),
    };
  });
  const decision = rowState?.decision ?? group.decision;
  const covered =
    !rowState?.problem && rowState?.coveredRequestCount === group.requestIds.length;
  const canCustomize = decision === `allow` && !covered;
  const canSelectApp = originalScope.current.type === `single`;
  const selectedScope = scopeChoice(group.key);
  const keychainSelectOptions = [
    ...keychainOptions.map((keychain) => ({ value: keychain.id, label: keychain.name })),
    { value: `personal`, label: `Personal keychain (automatic)` },
  ];
  const selectedKeychain = keychainOptions.find(
    (keychain) => keychain.id === group.keychainId,
  );

  const requestMessages = Array.from(
    new Set(
      group.requests.flatMap((request) => {
        const comment = request.requestComment?.trim();
        return comment ? [comment] : [];
      }),
    ),
  );
  const visibleRisk = group.risk;
  const domainHeadingRef = React.useRef<HTMLHeadingElement>(null);
  const [domainOverflowing, setDomainOverflowing] = React.useState(false);
  React.useLayoutEffect(() => {
    const heading = domainHeadingRef.current;
    if (!heading) return;
    const update = (): void =>
      setDomainOverflowing(heading.scrollWidth > heading.clientWidth + 1);
    update();
    const observer = new ResizeObserver(update);
    observer.observe(heading);
    return () => observer.disconnect();
  }, [group.target, canCustomize]);

  return (
    <div
      id={`unlock-${group.id}`}
      role="group"
      aria-label={`Request for ${group.target}${appName ? ` in ${appName}` : ` in web browsers`}`}
      className="grid scroll-mt-4 grid-cols-[auto_minmax(0,1fr)] items-start gap-x-2.5"
    >
      <div
        className={cx(
          `row-start-1 flex h-full items-center`,
          visibleRisk && `row-span-2`,
        )}
      >
        <DecisionButtons
          decision={decision}
          included={covered}
          setDecision={(decision) =>
            onChange(updateGroupDecision(group, decision, group.keychainId))
          }
        />
      </div>
      <Card
        padding={0}
        className={cx(
          `relative col-start-2 row-start-1 min-w-0 self-center overflow-hidden transition-opacity`,
          decision === `deny` && !rowState?.problem && `opacity-50`,
          covered && `!border-violet-200 !bg-violet-50/40`,
        )}
      >
        <VStack gap={covered ? 1 : 2.5} className="p-3">
          <VStack gap={1.5} className="min-w-0">
            <HStack
              gap={2}
              className={cx(`relative`, canCustomize && (customize ? `pr-32` : `pr-28`))}
            >
              <HStack gap={1.5} className="min-w-0 max-w-full">
                <Text
                  ref={domainHeadingRef}
                  as="h3"
                  variant="bodyLargeStrong"
                  className={cx(
                    `min-w-0 overflow-hidden leading-5 whitespace-nowrap @2xl/main:overflow-visible @2xl/main:whitespace-normal @2xl/main:break-all @2xl/main:[mask-image:none]`,
                    domainOverflowing &&
                      `[mask-image:linear-gradient(to_right,black_calc(100%-1.25rem),transparent)]`,
                    decision === `deny` && `line-through decoration-stone-500`,
                  )}
                >
                  {group.target}
                </Text>
                {requestCount(group) > 1 && (
                  <CountBadge size="compact">{requestCount(group)}</CountBadge>
                )}
              </HStack>
              {canCustomize && (
                <Button
                  type="button"
                  size="small"
                  variant="ghost"
                  icon={customize ? undefined : SettingsIcon}
                  className="!absolute -top-1 -right-1"
                  onClick={() => setCustomize((current) => !current)}
                  aria-expanded={customize}
                >
                  {customize ? `Close key settings` : `Key settings`}
                </Button>
              )}
            </HStack>
            {requestMessages.length > 0 && (
              <HStack wrap gap={1.5} align="start">
                {requestMessages.map((message) => (
                  <MessageBubble
                    key={message}
                    size="compact"
                    className="max-w-full break-words"
                  >
                    {message}
                  </MessageBubble>
                ))}
              </HStack>
            )}
            {group.requests.length > 1 && (
              <details className="group/requests mt-1 text-xs text-stone-600">
                <summary className="flex cursor-pointer list-none items-center gap-1 [&::-webkit-details-marker]:hidden">
                  <span>View all {group.requests.length} requests</span>
                  <ChevronRightIcon
                    aria-hidden="true"
                    className="size-3.5 shrink-0 transition-transform duration-150 group-open/requests:rotate-90 motion-reduce:transition-none"
                  />
                </summary>
                <ul className="mt-2 space-y-2">
                  {group.requests.map((request) => (
                    <li key={request.id} className="break-all">
                      {sanitizeRequestedAddress(request)}
                    </li>
                  ))}
                </ul>
              </details>
            )}
          </VStack>

          {rowState && rowState.coveredBy.length > 0 && (
            <div className="flex flex-wrap items-baseline gap-x-0.5 text-xs text-violet-950/75">
              <span>
                {covered || rowState.problem
                  ? `Included in your approval of`
                  : `${rowState.coveredRequestCount} of ${group.requestIds.length} requests included in your approval of`}
              </span>
              {rowState.coveredBy.map((source) => (
                <span
                  key={source.id}
                  className="inline-flex flex-wrap items-baseline gap-x-1"
                >
                  <a
                    className="break-all underline underline-offset-2"
                    href={`#unlock-${encodeURIComponent(source.id)}`}
                  >
                    {permissionLabel(source)}
                  </a>
                  {(!covered || rowState.coveredBy.length > 1) && (
                    <span className="text-stone-500">
                      (
                      {scopeChoice(source.key) === `unrestricted`
                        ? `all apps`
                        : scopeChoice(source.key) === `webBrowsers`
                          ? `web browsers`
                          : (source.requests[0]?.appName ??
                            source.requests[0]?.appBundleId ??
                            `requested app`)}
                      )
                    </span>
                  )}
                  {source.expiration && (
                    <span className="text-stone-500">
                      until {formatDate(new Date(source.expiration), `medium`)}
                    </span>
                  )}
                </span>
              ))}
            </div>
          )}

          {rowState?.overlaps && (
            <Text variant="captionSubtle">
              Another approval also includes this address. Both permissions will be saved;
              changing one won't restrict the other.
            </Text>
          )}
          {canCustomize &&
            selectedKeychain &&
            (selectedKeychain.schedule || selectedKeychain.otherPeople.length > 0) && (
              <KeychainDetails keychain={selectedKeychain} />
            )}

          {rowState?.problem && (
            <Banner variant="error" className="rounded-lg py-2 [&>div]:text-xs">
              {rowState.problem}
            </Banner>
          )}

          {canCustomize && (
            <>
              {customize && (
                <VStack
                  gap={3}
                  className="rounded-lg border border-stone-200 bg-stone-50 p-3"
                >
                  <div className="grid grid-cols-1 gap-3 @2xl/main:grid-cols-2">
                    {matchingOptions.length > 0 && (
                      <Select
                        label="Allow access to"
                        wrapLabels
                        defaultOpen={defaultMatchOptionsOpen}
                        selected={groupAddressMatch(group)}
                        possibleValues={matchingOptions}
                        setSelected={(match) =>
                          onChange(updateGroupKeyAddressMatch(group, match))
                        }
                      />
                    )}

                    <Select
                      label="Works in"
                      selected={selectedScope}
                      setSelected={(choice) =>
                        onChange({
                          ...group,
                          key: withScope(group.key, choice, originalScope.current),
                        })
                      }
                      possibleValues={scopeOptions(appName, canSelectApp)}
                    />
                    {keychainSelectOptions.length > 0 && (
                      <Select
                        label="Save to keychain"
                        selected={group.keychainId ?? `personal`}
                        setSelected={(keychainId) =>
                          onChange({
                            ...group,
                            keychainId:
                              keychainId === `personal` ? undefined : keychainId,
                          })
                        }
                        possibleValues={keychainSelectOptions}
                      />
                    )}
                    <DateTimePicker
                      label="Key expiration"
                      allowPast={false}
                      notRequired
                      date={group.expiration ? new Date(group.expiration) : undefined}
                      setDate={(expiration) =>
                        onChange({ ...group, expiration: expiration?.toISOString() })
                      }
                    />
                  </div>
                  <Textarea
                    label="Private note"
                    placeholder="Optional note for this key..."
                    rows={2}
                    resize="vertical"
                    value={group.comment ?? ``}
                    setValue={(comment) => onChange({ ...group, comment })}
                  />
                </VStack>
              )}
            </>
          )}
        </VStack>
      </Card>
      {visibleRisk && (
        <Banner
          variant={visibleRisk.level === `strongWarning` ? `error` : `warning`}
          className="col-start-2 row-start-2 mt-2 rounded-lg py-2 [&>svg]:h-4 [&>svg]:w-4 [&>div]:text-xs [&>div]:leading-4"
        >
          <strong>
            {visibleRisk.level === `strongWarning`
              ? `Deny recommended.`
              : `Review carefully.`}
          </strong>
          {` `}
          {visibleRisk.reason}
        </Banner>
      )}
    </div>
  );
};

const KeychainDetails: React.FC<{
  keychain?: GetPersonUnlockRequests.Output[`keychains`][number];
}> = ({ keychain }) => (
  <span className="block text-xs text-stone-600">
    {keychain?.name ?? `Personal keychain`} ·{` `}
    {keychain?.schedule ? formatSchedule(keychain.schedule) : `Always active`}
    {keychain &&
      keychain.otherPeople.length > 0 &&
      ` · Also grants access to ${keychain.otherPeople.join(`, `)}`}
  </span>
);

export default UnlockRequestCard;
