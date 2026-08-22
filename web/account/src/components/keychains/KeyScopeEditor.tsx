import {
  Badge,
  Card,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Input,
  Text,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, ChevronDownIcon, SearchIcon } from 'lucide-react';
import React from 'react';
import type {
  AppIdentificationType,
  KeyEditorApp,
  KeyEditorState,
  KeyScopeType,
  KeyTargetType,
} from './keyEditor';

type ScopeChoice = {
  value: KeyScopeType;
  title: string;
  description: string;
  badge?: string;
};

const scopeTarget = (targetType: KeyTargetType): string => {
  switch (targetType) {
    case `website`:
      return `this domain`;
    case `ipAddress`:
      return `this IP address`;
    case `domainRegex`:
      return `matching domains`;
  }
};

const scopeChoices = (targetType: KeyTargetType): ScopeChoice[] => {
  const target = scopeTarget(targetType);
  return [
    {
      value: `webBrowsers`,
      title: `Web browsers`,
      description: `Unlocks ${target} for Safari, Chrome, Firefox, and other browsers.`,
      badge: `Recommended`,
    },
    {
      value: `singleApp`,
      title: `One specific app`,
      description: `Unlocks ${target} only for one app you choose.`,
    },
    {
      value: `unrestricted`,
      title: `All apps`,
      description: `Unlocks ${target} for every app on assigned Macs.`,
    },
  ];
};

const scopeStepDescription = (targetType: KeyTargetType): string => {
  switch (targetType) {
    case `website`:
      return `Choose which apps to unlock this domain for.`;
    case `ipAddress`:
      return `Choose which apps to unlock this IP address for.`;
    case `domainRegex`:
      return `Choose which apps to unlock matching domains for.`;
  }
};

const ScopeChoiceRow: React.FC<{
  choice: ScopeChoice;
  selected: KeyScopeType;
  setSelected: (value: KeyScopeType) => void;
  disabled: boolean;
}> = ({ choice, selected, setSelected, disabled }) => {
  const id = React.useId();
  const checked = choice.value === selected;

  return (
    <label
      htmlFor={id}
      className={cx(
        `flex cursor-pointer border-t border-stone-200 px-4 py-3 first:border-t-0 hover:bg-stone-50`,
        disabled && `cursor-not-allowed opacity-60`,
      )}
    >
      <input
        id={id}
        type="radio"
        name="key-app-scope"
        value={choice.value}
        checked={checked}
        disabled={disabled}
        onChange={() => setSelected(choice.value)}
        className="peer sr-only"
      />
      <HStack gap={4}>
        <HStack
          justify="center"
          className={cx(
            `h-5 w-5 shrink-0 rounded-full border peer-focus-visible:ring-2 peer-focus-visible:ring-violet-300/80 peer-focus-visible:ring-offset-2`,
            checked ? `border-violet-500 bg-violet-500` : `border-stone-200 bg-white`,
          )}
        >
          {checked && (
            <CheckIcon
              className="h-3.5 w-3.5 translate-y-[0.5px] text-white"
              strokeWidth={3}
            />
          )}
        </HStack>
        <VStack gap={0.5}>
          <HStack wrap gap={2}>
            <Text variant="bodyLarge">{choice.title}</Text>
            {choice.badge && (
              <Badge size="small" color="green">
                {choice.badge}
              </Badge>
            )}
          </HStack>
          <Text variant="bodySubtle">{choice.description}</Text>
        </VStack>
      </HStack>
    </label>
  );
};

const ScopeChoiceGroup: React.FC<{
  targetType: KeyTargetType;
  selected: KeyScopeType;
  setSelected: (value: KeyScopeType) => void;
  disabled: boolean;
}> = ({ targetType, selected, setSelected, disabled }) => (
  <div className="overflow-hidden rounded-xl border border-stone-200 bg-white shadow shadow-stone-300/30">
    {scopeChoices(targetType).map((choice) => (
      <ScopeChoiceRow
        key={choice.value}
        choice={choice}
        selected={selected}
        setSelected={setSelected}
        disabled={disabled}
      />
    ))}
  </div>
);

const AppIcon: React.FC<{ app: KeyEditorApp; className?: string }> = ({
  app,
  className,
}) => {
  if (app.appIconUrl) {
    return (
      <img
        src={app.appIconUrl}
        alt=""
        className={cx(`shrink-0 object-contain`, className)}
      />
    );
  }

  return (
    <span
      className={cx(
        `flex shrink-0 items-center justify-center rounded-md bg-stone-200 text-xs font-semibold text-stone-500`,
        className,
      )}
    >
      {app.name.slice(0, 1).toUpperCase()}
    </span>
  );
};

const AppPicker: React.FC<{
  apps: KeyEditorApp[];
  selectedSlug: string;
  setSelectedSlug: (slug: string) => void;
  disabled?: boolean;
}> = ({ apps, selectedSlug, setSelectedSlug, disabled = false }) => {
  const selectedApp = apps.find((app) => app.slug === selectedSlug);

  return (
    <VStack gap={1}>
      <Text variant="label" className="ml-2.5">
        Application
      </Text>
      <DropdownMenu
        searchable
        disabled={disabled}
        contentClassName="w-[min(22rem,calc(100vw-2rem))] max-h-96 overflow-y-auto"
        trigger={
          <button
            type="button"
            className="flex min-h-[36.5px] w-full items-center overflow-hidden rounded-[9px] border border-stone-300/80 bg-white text-left shadow shadow-stone-300/30 outline-none transition-[border-color,box-shadow] hover:border-stone-400/70 focus-visible:border-violet-300 focus-visible:ring-2 focus-visible:ring-violet-200/70"
          >
            <HStack gap={2} className="min-w-0 flex-grow px-2.5 py-1.25">
              {selectedApp ? (
                <AppIcon app={selectedApp} className="h-5 w-5" />
              ) : (
                <SearchIcon className="h-3.5 w-3.5 shrink-0 text-stone-400" />
              )}
              <Text
                variant="body"
                className={cx(
                  `truncate`,
                  selectedApp ? `text-stone-900` : `text-stone-400`,
                )}
              >
                {selectedApp?.name ?? (selectedSlug || `Choose an app`)}
              </Text>
            </HStack>
            <HStack className="self-stretch px-2.5 text-stone-400">
              <ChevronDownIcon className="h-4 w-4" />
            </HStack>
          </button>
        }
      >
        {apps.map((app) => (
          <DropdownMenuItem
            key={app.slug}
            title={app.name}
            description={app.bundleId}
            descriptionClassName="break-words hyphens-auto"
            icon={<AppIcon app={app} className="!h-7 !w-7" />}
            selected={app.slug === selectedSlug}
            onSelect={() => setSelectedSlug(app.slug)}
          />
        ))}
      </DropdownMenu>
    </VStack>
  );
};

type Props = {
  state: KeyEditorState;
  apps: KeyEditorApp[];
  disabled: boolean;
  changeScope: (scopeType: KeyScopeType) => void;
  changeAppIdentificationType: (appIdentificationType: AppIdentificationType) => void;
  changeAppSlug: (appSlug: string) => void;
  changeAppBundleId: (appBundleId: string) => void;
};

const KeyScopeEditor: React.FC<Props> = ({
  state,
  apps,
  disabled,
  changeScope,
  changeAppIdentificationType,
  changeAppSlug,
  changeAppBundleId,
}) => (
  <VStack gap={4}>
    <VStack gap={1}>
      <Text as="h2" variant="heading">
        Where should it work?
      </Text>
      <Text variant="bodySubtle" className="leading-6">
        {scopeStepDescription(state.targetType)}
      </Text>
    </VStack>

    <ScopeChoiceGroup
      targetType={state.targetType}
      selected={state.scopeType}
      setSelected={changeScope}
      disabled={disabled}
    />

    {state.scopeType === `singleApp` && (
      <Card padding={3}>
        <VStack gap={3}>
          <div className="grid grid-cols-2 rounded-lg bg-stone-100 p-1">
            {(
              [
                [`identifiedAppSlug`, `Common apps`],
                [`bundleId`, `Bundle ID`],
              ] as const
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                disabled={disabled}
                onClick={() => changeAppIdentificationType(value)}
                className={cx(
                  `cursor-pointer rounded-md border px-2 py-1 text-sm font-medium outline-none transition-colors focus-visible:ring-2 focus-visible:ring-violet-300/80 disabled:cursor-not-allowed disabled:opacity-60`,
                  state.appIdentificationType === value
                    ? `border-stone-200 bg-white text-stone-900 shadow-sm`
                    : `border-transparent text-stone-600 hover:bg-stone-200/60`,
                )}
              >
                {label}
              </button>
            ))}
          </div>
          {state.appIdentificationType === `identifiedAppSlug` ? (
            <AppPicker
              apps={apps}
              selectedSlug={state.appSlug}
              setSelectedSlug={changeAppSlug}
              disabled={disabled}
            />
          ) : (
            <Input
              type="text"
              label="App bundle ID"
              value={state.appBundleId}
              setValue={changeAppBundleId}
              placeholder="com.example.application"
              helperText="Find this identifier in the app's technical information."
              disabled={disabled}
            />
          )}
        </VStack>
      </Card>
    )}
  </VStack>
);

export default KeyScopeEditor;
