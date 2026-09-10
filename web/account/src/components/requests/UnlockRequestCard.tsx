import {
  Badge,
  Banner,
  Button,
  Card,
  DateTimePicker,
  HStack,
  Select,
  Text,
  Textarea,
  Toggle,
  Tooltip,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  BanIcon,
  CheckIcon,
  GlobeIcon,
  LayoutGridIcon,
  MonitorIcon,
  SettingsIcon,
} from 'lucide-react';
import React from 'react';
import type { SharedKey } from '#/components/types';
import type { UnlockDomainGroup } from '#/lib/unlockRequests';
import type { SelectOption } from '@gertrude/ui';
import type { AppScope } from '@shared/pairql/src/account';
import MessageBubble from '#/components/MessageBubble';
import { updateGroupKeyAddressMatch } from '#/lib/unlockRequests';

interface Props {
  group: UnlockDomainGroup;
  keychainOptions: Array<{ id: string; name: string }>;
  appName?: string;
  onChange: (group: UnlockDomainGroup) => void;
}

type ScopeChoice = `webBrowsers` | `singleApp` | `unrestricted`;

const requestCount = (group: UnlockDomainGroup): number => group.requestIds.length;

const scopeChoice = (key: SharedKey): ScopeChoice => {
  if (!(`scope` in key) || key.scope.type === `webBrowsers`) {
    return `webBrowsers`;
  }
  return key.scope.type === `single` ? `singleApp` : `unrestricted`;
};

const withScope = (
  key: SharedKey,
  choice: ScopeChoice,
  originalScope: AppScope,
): SharedKey => {
  if (key.type === `skeleton`) {
    return key;
  }
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
  {
    value: `webBrowsers`,
    label: `Web browsers`,
    description: `Safari, Chrome, Firefox, and other browsers`,
    icon: GlobeIcon,
  },
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
  setDecision: (decision: UnlockDomainGroup[`decision`]) => void;
}> = ({ decision, setDecision }) => (
  <div className="inline-flex shrink-0 flex-col rounded-full border border-stone-200 bg-stone-100 p-0.5">
    {([`deny`, `allow`] as const).map((choice) => {
      const Icon = choice === `deny` ? BanIcon : CheckIcon;
      const selected = decision === choice;
      const label = choice === `deny` ? `Deny request` : `Allow request`;
      return (
        <Tooltip key={choice} content={selected ? `Clear decision` : label} side="left">
          <button
            type="button"
            aria-label={selected ? `Clear decision` : label}
            aria-pressed={selected}
            onClick={() => setDecision(selected ? `undecided` : choice)}
            className={cx(
              `flex h-7 w-7 cursor-pointer items-center justify-center rounded-full border outline-none transition-colors focus-visible:ring-2 focus-visible:ring-violet-300 focus-visible:ring-offset-1`,
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
  onChange,
}) => {
  const [customize, setCustomize] = React.useState(false);
  const originalScope = React.useRef<AppScope>(
    group.key.type === `skeleton` ? { type: `webBrowsers` } : group.key.scope,
  );
  const includeSubdomains = group.key.type === `anySubdomain`;
  const canChangeMatch = group.key.type === `domain` || group.key.type === `anySubdomain`;
  const canSelectApp = originalScope.current.type === `single`;
  const selectedScope = scopeChoice(group.key);
  const keychainSelectOptions = keychainOptions.map((keychain) => ({
    value: keychain.id,
    label: keychain.name,
  }));

  const requestMessage = group.requests.find(
    (request) => request.requestComment,
  )?.requestComment;
  const visibleRisk = group.decision === `deny` ? undefined : group.risk;

  return (
    <div className="grid grid-cols-[auto_minmax(0,1fr)] items-start gap-x-2.5">
      <div
        className={cx(
          `row-start-1 flex h-full items-center`,
          visibleRisk && `row-span-2`,
        )}
      >
        <DecisionButtons
          decision={group.decision}
          setDecision={(decision) => onChange({ ...group, decision })}
        />
      </div>
      <Card
        padding={0}
        className={cx(
          `relative col-start-2 row-start-1 min-w-0 self-center overflow-hidden transition-opacity`,
          group.decision === `deny` && `opacity-50`,
        )}
      >
        <VStack gap={2.5} className="p-3">
          <VStack
            gap={1.5}
            className={cx(`relative min-w-0`, group.decision === `allow` && `pr-32`)}
          >
            <HStack wrap gap={1.5}>
              <Text
                as="h3"
                variant="bodyLargeStrong"
                className={cx(
                  `break-all leading-5`,
                  group.decision === `deny` && `line-through decoration-stone-500`,
                )}
              >
                {group.target}
              </Text>
              {requestCount(group) > 1 && (
                <Badge size="small" color="neutral">
                  Requested {requestCount(group)} times
                </Badge>
              )}
            </HStack>
            {requestMessage && (
              <MessageBubble size="compact">{requestMessage}</MessageBubble>
            )}
            {group.decision === `allow` && (
              <Button
                type="button"
                size="small"
                variant="ghost"
                icon={customize ? undefined : SettingsIcon}
                className="!absolute -right-1 -bottom-1"
                onClick={() => setCustomize((current) => !current)}
                aria-expanded={customize}
              >
                {customize ? `Close key settings` : `Key settings`}
              </Button>
            )}
          </VStack>

          {group.decision === `allow` && (
            <>
              {customize && (
                <VStack
                  gap={3}
                  className="rounded-lg border border-stone-200 bg-stone-50 p-3"
                >
                  {canChangeMatch && (
                    <HStack justify="between" gap={4}>
                      <VStack gap={0.5}>
                        <Text variant="bodyStrong">Include subdomains</Text>
                        <Text variant="captionSubtle">
                          {includeSubdomains
                            ? `Allows this domain and addresses underneath it.`
                            : `Allows only the exact requested host.`}
                        </Text>
                      </VStack>
                      <Toggle
                        checked={includeSubdomains}
                        setChecked={(checked) =>
                          onChange(updateGroupKeyAddressMatch(group, checked))
                        }
                        ariaLabel="Include subdomains"
                      />
                    </HStack>
                  )}

                  <div className="grid grid-cols-1 gap-3 @2xl/main:grid-cols-2">
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
                        selected={
                          group.keychainId ?? keychainSelectOptions[0]?.value ?? ``
                        }
                        setSelected={(keychainId) => onChange({ ...group, keychainId })}
                        possibleValues={keychainSelectOptions}
                      />
                    )}
                    <DateTimePicker
                      label="Expiration date"
                      notRequired
                      date={group.expiration ? new Date(group.expiration) : undefined}
                      setDate={(expiration) =>
                        onChange({ ...group, expiration: expiration?.toISOString() })
                      }
                    />
                    <Textarea
                      label="Private note"
                      placeholder="Optional note for this key..."
                      rows={2}
                      resize="vertical"
                      value={group.comment ?? ``}
                      setValue={(comment) => onChange({ ...group, comment })}
                    />
                  </div>
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

export default UnlockRequestCard;
