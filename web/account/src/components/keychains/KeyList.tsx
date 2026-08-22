import {
  Badge,
  Card,
  EmptyState,
  HStack,
  Input,
  Stack,
  Text,
  VStack,
  inflect,
} from '@gertrude/ui';
import { formatDate, formatTime } from '@shared/datetime';
import cx from 'clsx';
import {
  AppWindowIcon,
  ClockIcon,
  GlobeIcon,
  KeyIcon,
  type LucideIcon,
  NetworkIcon,
  RegexIcon,
  RouteIcon,
  SearchXIcon,
} from 'lucide-react';
import React from 'react';
import type { KeychainKey, SharedKey } from '#/components/types';
import type { AppScope, SingleAppScope } from '@shared/pairql/src/account';
import MessageBubble from '#/components/MessageBubble';

type KeyTargetPresentation = {
  target: string;
  accentPrefix?: string;
  kind: string;
  Icon: LucideIcon;
  monospace: boolean;
  marker?: `advanced` | `legacy`;
};

type KeyScopePresentation = {
  label: string;
  detail: string;
  identifier?: string;
  monospace: boolean;
};

export type KeyPresentation = {
  target: KeyTargetPresentation;
  scope: KeyScopePresentation;
};

interface Props {
  keys: KeychainKey[];
  onEdit?: (key: KeychainKey) => void;
}

const targetPresentation = (key: SharedKey): KeyTargetPresentation => {
  switch (key.type) {
    case `anySubdomain`:
      return {
        target: `*.${key.domain}`,
        accentPrefix: `*.`,
        kind: `Domain and all subdomains`,
        Icon: GlobeIcon,
        monospace: true,
      };
    case `domain`:
      return {
        target: key.domain,
        kind: `Specific domain`,
        Icon: GlobeIcon,
        monospace: true,
      };
    case `domainRegex`:
      return {
        target: key.pattern,
        kind: `Domain pattern`,
        Icon: RegexIcon,
        monospace: true,
        marker: `advanced`,
      };
    case `ipAddress`:
      return {
        target: key.ipAddress,
        kind: `IP address`,
        Icon: NetworkIcon,
        monospace: true,
      };
    case `path`:
      return {
        target: key.path,
        kind: `Specific path`,
        Icon: RouteIcon,
        monospace: true,
        marker: `legacy`,
      };
    case `skeleton`:
      return {
        target: `Unrestricted internet access`,
        kind: `App key`,
        Icon: AppWindowIcon,
        monospace: false,
      };
  }
};

const singleAppScopePresentation = (
  scope: SingleAppScope,
  appName?: string,
): KeyScopePresentation => {
  if (scope.type === `identifiedAppSlug`) {
    return {
      label: appName ?? scope.identifiedAppSlug,
      detail: appName ? `Specific app` : `Specific app · Catalog identifier`,
      identifier: scope.identifiedAppSlug,
      monospace: appName === undefined,
    };
  }

  return {
    label: appName ?? scope.bundleId,
    detail: appName ? `Specific app` : `Specific app · Bundle ID`,
    identifier: scope.bundleId,
    monospace: appName === undefined,
  };
};

const scopePresentation = (
  scope: AppScope | SingleAppScope,
  appName?: string,
): KeyScopePresentation => {
  switch (scope.type) {
    case `unrestricted`:
      return {
        label: `All apps`,
        detail: `Every app on assigned Macs`,
        monospace: false,
      };
    case `webBrowsers`:
      return {
        label: `Web browsers`,
        detail: `Chrome, Safari, Firefox, and others`,
        monospace: false,
      };
    case `single`:
      return singleAppScopePresentation(scope.single, appName);
    case `identifiedAppSlug`:
    case `bundleId`:
      return singleAppScopePresentation(scope, appName);
  }
};

type KeyDisplayRecord = Omit<KeychainKey, `id`>;

export const keyPresentation = (record: KeyDisplayRecord): KeyPresentation => ({
  target: targetPresentation(record.key),
  scope: scopePresentation(record.key.scope, record.appName),
});

const expirationText = (expiration: string): string => {
  const date = new Date(expiration);
  const prefix = date.getTime() <= Date.now() ? `Expired` : `Expires`;
  return `${prefix} ${formatDate(date, `medium`)} at ${formatTime(date)}`;
};

export const KeyDisplay: React.FC<{
  record: KeyDisplayRecord;
  alwaysShowLabels?: boolean;
  className?: string;
}> = ({ record, alwaysShowLabels = false, className }) => {
  const presentation = keyPresentation(record);
  const TargetIcon = presentation.target.Icon;

  return (
    <div
      className={cx(
        `grid grid-cols-1 gap-4 px-3 py-2.5 @2xl/main:grid-cols-[minmax(0,1.35fr)_minmax(13rem,0.8fr)] @2xl/main:items-center @2xl/main:gap-6 @2xl/main:px-4`,
        className,
      )}
    >
      <VStack gap={0.5} className="min-w-0">
        <Text
          variant="captionMuted"
          className={cx(
            `uppercase tracking-[0.12em]`,
            !alwaysShowLabels && `@2xl/main:hidden`,
          )}
        >
          Unlocks:
        </Text>
        <HStack align="start" gap={2.5} className="min-w-0">
          <TargetIcon
            className="mt-0.5 hidden h-4 w-4 shrink-0 text-stone-400 @2xl/main:block"
            strokeWidth={1.8}
          />
          <VStack gap={0.5} className="min-w-0">
            <Text
              as={presentation.target.monospace ? `code` : `span`}
              variant={presentation.target.monospace ? `code` : `bodyStrong`}
              className="break-all font-semibold leading-5 text-stone-900"
            >
              {presentation.target.accentPrefix && (
                <span className="text-violet-400">
                  {presentation.target.accentPrefix}
                </span>
              )}
              {presentation.target.target.slice(
                presentation.target.accentPrefix?.length ?? 0,
              )}
            </Text>
            <HStack wrap gap={1.5}>
              <Text variant="captionSubtle">{presentation.target.kind}</Text>
              {presentation.target.marker === `advanced` && (
                <Badge size="xsmall" color="yellow">
                  Advanced
                </Badge>
              )}
              {presentation.target.marker === `legacy` && (
                <Badge size="xsmall">Legacy</Badge>
              )}
            </HStack>
            {record.comment && (
              <MessageBubble size="compact" className="mt-1 max-w-full break-words">
                {record.comment}
              </MessageBubble>
            )}
            {record.expiration && (
              <HStack as="span" gap={1.5} className="mt-0.5">
                <ClockIcon className="h-3.5 w-3.5 shrink-0 text-amber-600" />
                <Text variant="caption" className="text-amber-800">
                  {expirationText(record.expiration)}
                </Text>
              </HStack>
            )}
          </VStack>
        </HStack>
      </VStack>

      <VStack gap={0.5} className="min-w-0">
        <Text
          variant="captionMuted"
          className={cx(
            `uppercase tracking-[0.12em]`,
            !alwaysShowLabels && `@2xl/main:hidden`,
          )}
        >
          For:
        </Text>
        <VStack gap={0.5} className="min-w-0">
          <Text
            as={presentation.scope.monospace ? `code` : `span`}
            variant={presentation.scope.monospace ? `code` : `bodyStrong`}
            className="break-all leading-5 text-stone-900"
          >
            {presentation.scope.label || `Unidentified app`}
          </Text>
          <Text variant="captionSubtle" className="leading-5">
            {presentation.scope.detail}
          </Text>
        </VStack>
      </VStack>
    </div>
  );
};

const KeyRow: React.FC<{
  record: KeychainKey;
  onEdit?: (key: KeychainKey) => void;
}> = ({ record, onEdit }) => {
  const presentation = keyPresentation(record);
  const editable =
    onEdit !== undefined && record.key.type !== `path` && record.key.type !== `skeleton`;
  const content = <KeyDisplay record={record} />;

  return (
    <li className="border-b border-stone-200/70 last:border-b-0">
      {editable ? (
        <button
          type="button"
          onClick={() => onEdit?.(record)}
          className="block w-full cursor-pointer text-left outline-none transition-colors hover:bg-violet-50/40 focus-visible:bg-violet-50 focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-300/80"
          aria-label={`Edit key for ${presentation.target.target}`}
        >
          {content}
        </button>
      ) : (
        content
      )}
    </li>
  );
};

const searchableText = (record: KeychainKey): string => {
  const presentation = keyPresentation(record);
  return [
    presentation.target.target,
    presentation.target.kind,
    presentation.scope.label,
    presentation.scope.detail,
    presentation.scope.identifier,
    record.comment,
  ]
    .filter((value) => value !== undefined)
    .join(` `)
    .toLowerCase();
};

const KeyList: React.FC<Props> = ({ keys, onEdit }) => {
  const [searchQuery, setSearchQuery] = React.useState(``);
  const searchInputId = React.useId();
  const normalizedSearchQuery = searchQuery.trim().toLowerCase();
  const filteredKeys = normalizedSearchQuery
    ? keys.filter((key) => searchableText(key).includes(normalizedSearchQuery))
    : keys;

  if (keys.length === 0) {
    return (
      <EmptyState
        icon={KeyIcon}
        title="No keys"
        description="This keychain doesn't unlock anything yet."
        className="bg-white"
      />
    );
  }

  return (
    <Card padding={0} className="overflow-hidden">
      <Stack
        justify="between"
        align={{ default: `stretch`, '@2xl/main': `end` }}
        direction={{ default: `vertical`, '@2xl/main': `horizontal` }}
        gap={3}
        className="border-b border-stone-200 bg-stone-50/70 px-3 py-3 @2xl/main:px-4"
      >
        <VStack gap={0.5}>
          <Text as="h2" variant="bodyLargeStrong">
            Keys
          </Text>
          <Text variant="captionMuted">
            {keys.length} {inflect(`key`, keys.length)} in this keychain
          </Text>
        </VStack>
        {keys.length >= 8 && (
          <HStack gap={2} align="center" className="min-w-0 flex-grow @2xl/main:w-auto">
            <Text
              as="label"
              htmlFor={searchInputId}
              variant="label"
              className="hidden shrink-0 @lg/main:block"
            >
              Search keys
            </Text>
            <Input
              id={searchInputId}
              type="text"
              value={searchQuery}
              setValue={setSearchQuery}
              placeholder="Address, app, or comment…"
              className="min-w-0 flex-1 @2xl/main:w-80 @2xl/main:flex-none"
            />
          </HStack>
        )}
      </Stack>

      <div className="hidden grid-cols-[minmax(0,1.35fr)_minmax(13rem,0.8fr)] gap-6 border-b border-stone-200/70 bg-white px-4 py-2 @2xl/main:grid">
        <Text variant="captionMuted" className="pl-6 uppercase tracking-[0.14em]">
          Unlocks
        </Text>
        <Text variant="captionMuted" className="uppercase tracking-[0.14em]">
          For
        </Text>
      </div>

      {filteredKeys.length > 0 ? (
        <ul>
          {filteredKeys.map((key) => (
            <KeyRow key={key.id} record={key} onEdit={onEdit} />
          ))}
        </ul>
      ) : (
        <VStack align="center" gap={2} className="px-4 py-12 text-center">
          <SearchXIcon className="h-7 w-7 text-stone-400" />
          <Text variant="bodyStrong">No matching keys</Text>
          <Text variant="bodyMuted">Try a different address, app, or comment.</Text>
        </VStack>
      )}
    </Card>
  );
};

export default KeyList;
