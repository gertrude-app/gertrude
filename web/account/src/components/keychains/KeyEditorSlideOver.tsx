import {
  Badge,
  Banner,
  Button,
  Card,
  ConfirmationDialog,
  DateTimePicker,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Input,
  Select,
  SlideOver,
  Spacer,
  Text,
  Textarea,
  Toggle,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  ArrowLeftIcon,
  ArrowRightIcon,
  CheckIcon,
  ChevronDownIcon,
  ClockIcon,
  FileTextIcon,
  GlobeIcon,
  KeyRoundIcon,
  NetworkIcon,
  RegexIcon,
  SearchIcon,
  TrashIcon,
} from 'lucide-react';
import React from 'react';
import type { KeychainKey, SharedKey } from '#/components/types';
import { KeyDisplay } from './KeyList';
import {
  type AppIdentificationType,
  type DomainMatchType,
  type KeyEditorState,
  type KeyScopeType,
  type KeyTargetType,
  broadAccessWarning,
  domainDetails,
  inferredDomainMatch,
  keyEditorError,
  keyFromEditorState,
  keyToEditorState,
  newKeyEditorState,
} from './keyEditor';

export type KeyEditorSaveData = {
  key: SharedKey;
  comment?: string;
  expiration?: Date;
};

type AppOption = {
  name: string;
  slug: string;
  bundleId?: string;
  appIconUrl?: string;
};
type EditorStage = `target` | `scope` | `review`;

type Props = {
  open: boolean;
  apps: AppOption[];
  saving: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (data: KeyEditorSaveData) => Promise<void>;
};

const targetTypeOptions = [
  {
    value: `website`,
    label: `Website address`,
    description: `Allow a domain or hostname`,
    icon: GlobeIcon,
  },
  {
    value: `ipAddress`,
    label: `IP address`,
    description: `Allow a network address`,
    icon: NetworkIcon,
  },
  {
    value: `domainRegex`,
    label: `Domain pattern`,
    description: `Match hostnames with a regular expression`,
    icon: RegexIcon,
  },
] as const;

const targetInputCopy = (
  targetType: KeyTargetType,
): { label: string; placeholder: string; helperText?: string } => {
  switch (targetType) {
    case `website`:
      return {
        label: `Website address`,
        placeholder: `example.com or https://school.example.com`,
      };
    case `ipAddress`:
      return {
        label: `IP address`,
        placeholder: `192.0.2.1`,
        helperText: `IPv4 and IPv6 addresses are supported.`,
      };
    case `domainRegex`:
      return {
        label: `Domain pattern`,
        placeholder: `^.*\\.edu$`,
        helperText: `Case-insensitive regular expression matched against the hostname only.`,
      };
  }
};

const targetStepDescription = (targetType: KeyTargetType): string => {
  switch (targetType) {
    case `website`:
      return `Paste a full URL or enter a domain. Gertrude will keep only the part used for filtering.`;
    case `ipAddress`:
      return `Enter the network address that assigned Macs should be allowed to reach.`;
    case `domainRegex`:
      return `Enter a regular expression for the hostnames this key should allow.`;
  }
};

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

const flowStages: Array<{ stage: EditorStage; label: string }> = [
  { stage: `target`, label: `Address` },
  { stage: `scope`, label: `Where it works` },
  { stage: `review`, label: `Review` },
];

const FlowProgress: React.FC<{ stage: EditorStage }> = ({ stage }) => {
  const activeIndex = flowStages.findIndex((item) => item.stage === stage);

  return (
    <div className="grid grid-cols-3 gap-2" aria-label="Key setup progress">
      {flowStages.map((item, index) => (
        <VStack key={item.stage} gap={1}>
          <div
            className={cx(
              `h-1 rounded-full transition-colors`,
              index <= activeIndex ? `bg-violet-500` : `bg-stone-200`,
            )}
          />
          <Text
            variant={index === activeIndex ? `captionStrong` : `captionMuted`}
            className={cx(index < activeIndex && `text-violet-700`)}
            aria-current={index === activeIndex ? `step` : undefined}
          >
            {item.label}
          </Text>
        </VStack>
      ))}
    </div>
  );
};

const StageIntro: React.FC<{
  title: string;
  description: string;
}> = ({ title, description }) => (
  <VStack gap={1}>
    <Text as="h2" variant="heading">
      {title}
    </Text>
    <Text variant="bodySubtle" className="leading-6">
      {description}
    </Text>
  </VStack>
);

const AppIcon: React.FC<{ app: AppOption; className?: string }> = ({
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
  apps: AppOption[];
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

const subdomainExamples = (state: KeyEditorState): string[] => {
  const details = domainDetails(state.address);
  if (!details) {
    return [];
  }

  const examples = details.hasSubdomain ? [details.hostname] : [];
  for (const prefix of [`images`, `api`, `docs`]) {
    const example = `${prefix}.${details.registrableDomain}`;
    if (!examples.includes(example)) {
      examples.push(example);
    }
  }
  return examples.slice(0, 3);
};

const MatchingEditor: React.FC<{
  state: KeyEditorState;
  disabled: boolean;
  changeMatching: (domainMatch: DomainMatchType) => void;
}> = ({ state, disabled, changeMatching }) => {
  const details = domainDetails(state.address);
  const includeSubdomains = state.domainMatch === `standard`;
  const examples = subdomainExamples(state);

  return (
    <Card padding={3}>
      <HStack justify="between" gap={4}>
        <VStack gap={0.5} className="min-w-0">
          <Text variant="bodyStrong">Include subdomains</Text>
          <Text variant="captionSubtle" className="leading-5">
            {`Allow any hostname underneath ${details?.registrableDomain ?? `this website`}, like `}
            {examples.map((example, index) => (
              <React.Fragment key={example}>
                {index > 0 && (index === examples.length - 1 ? `, or ` : `, `)}
                <Text as="code" variant="code" className="text-xs">
                  {example}
                </Text>
              </React.Fragment>
            ))}
            .
          </Text>
        </VStack>
        <Toggle
          checked={includeSubdomains}
          setChecked={(checked) => changeMatching(checked ? `standard` : `strict`)}
          disabled={disabled}
          ariaLabel="Include subdomains"
        />
      </HStack>
    </Card>
  );
};

const TargetEditor: React.FC<{
  state: KeyEditorState;
  inputId: string;
  error: string | null;
  warning: string | null;
  disabled: boolean;
  changeTargetType: (targetType: KeyTargetType) => void;
  changeAddress: (address: string) => void;
  changeMatching: (domainMatch: DomainMatchType) => void;
}> = ({
  state,
  inputId,
  error,
  warning,
  disabled,
  changeTargetType,
  changeAddress,
  changeMatching,
}) => {
  const inputCopy = targetInputCopy(state.targetType);
  const targetKey = keyFromEditorState({ ...state, scopeType: `webBrowsers` });

  return (
    <VStack gap={4}>
      <StageIntro
        title="What should this key allow?"
        description={targetStepDescription(state.targetType)}
      />

      <div className="grid grid-cols-1 items-start gap-2 @lg/slide:grid-cols-[minmax(0,1.25fr)_minmax(0,0.75fr)]">
        <Input
          id={inputId}
          type="text"
          label={inputCopy.label}
          value={state.address}
          setValue={changeAddress}
          placeholder={inputCopy.placeholder}
          helperText={inputCopy.helperText}
          error={error ?? undefined}
          autoComplete="off"
          disabled={disabled}
        />
        <Select
          selected={state.targetType}
          setSelected={changeTargetType}
          possibleValues={targetTypeOptions}
          disabled={disabled}
          className="min-w-0 @lg/slide:mt-[24px]"
        />
      </div>

      {state.targetType === `website` && targetKey && (
        <MatchingEditor
          state={state}
          disabled={disabled}
          changeMatching={changeMatching}
        />
      )}

      {warning && <Banner variant="warning">{warning}</Banner>}
    </VStack>
  );
};

const ScopeEditor: React.FC<{
  state: KeyEditorState;
  apps: AppOption[];
  disabled: boolean;
  changeScope: (scopeType: KeyScopeType) => void;
  changeAppIdentificationType: (appIdentificationType: AppIdentificationType) => void;
  changeAppSlug: (appSlug: string) => void;
  changeAppBundleId: (appBundleId: string) => void;
}> = ({
  state,
  apps,
  disabled,
  changeScope,
  changeAppIdentificationType,
  changeAppSlug,
  changeAppBundleId,
}) => (
  <VStack gap={4}>
    <StageIntro
      title="Where should it work?"
      description={scopeStepDescription(state.targetType)}
    />

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

type EditKeySlideOverProps = Props & {
  keyRecord: KeychainKey;
  deleting: boolean;
  onDelete: () => Promise<void>;
};

export const EditKeySlideOver: React.FC<EditKeySlideOverProps> = ({
  open,
  keyRecord,
  apps,
  saving,
  deleting,
  onOpenChange,
  onSave,
  onDelete,
}) => {
  const formId = React.useId();
  const targetInputId = React.useId();
  const [state, setState] = React.useState<KeyEditorState>(
    () => keyToEditorState(keyRecord) ?? newKeyEditorState(),
  );

  React.useEffect(() => {
    if (!open) {
      return;
    }
    const nextState = keyToEditorState(keyRecord);
    if (nextState) {
      setState(nextState);
    }
  }, [keyRecord, open]);

  const key = keyFromEditorState(state);
  const error = keyEditorError(state);
  const warning = broadAccessWarning(state);
  const disabled = saving || deleting;

  const changeTargetType = (targetType: KeyTargetType): void => {
    setState((current) => ({
      ...current,
      targetType,
      address: targetType === current.targetType ? current.address : ``,
      domainMatch: `standard`,
      matchingOverridden: false,
    }));
  };

  const changeAddress = (address: string): void => {
    setState((current) => ({
      ...current,
      address,
      domainMatch:
        current.targetType === `website` && !current.matchingOverridden
          ? inferredDomainMatch(address)
          : current.domainMatch,
    }));
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    if (!key || disabled) {
      return;
    }

    const comment = state.comment.trim();
    void onSave({
      key,
      comment: comment || undefined,
      expiration: state.expiration,
    }).then(
      () => onOpenChange(false),
      () => undefined,
    );
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={onOpenChange}
      ariaLabel="Edit key"
      heading="Edit key"
      subheading="Update what this key allows and where it works."
      size="large"
      dismissible={!disabled}
    >
      <VStack className="h-full">
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          <form id={formId} onSubmit={handleSubmit}>
            <VStack gap={6}>
              <TargetEditor
                state={state}
                inputId={targetInputId}
                error={error}
                warning={warning}
                disabled={disabled}
                changeTargetType={changeTargetType}
                changeAddress={changeAddress}
                changeMatching={(domainMatch) =>
                  setState((current) => ({
                    ...current,
                    domainMatch,
                    matchingOverridden: true,
                  }))
                }
              />

              <ScopeEditor
                state={state}
                apps={apps}
                disabled={disabled}
                changeScope={(scopeType) =>
                  setState((current) => ({ ...current, scopeType }))
                }
                changeAppIdentificationType={(appIdentificationType) =>
                  setState((current) => ({ ...current, appIdentificationType }))
                }
                changeAppSlug={(appSlug) =>
                  setState((current) => ({ ...current, appSlug }))
                }
                changeAppBundleId={(appBundleId) =>
                  setState((current) => ({ ...current, appBundleId }))
                }
              />

              <VStack gap={4}>
                <StageIntro
                  title="Anything else?"
                  description="Expiration and notes are optional."
                />
                <DateTimePicker
                  label="Expiration"
                  date={state.expiration}
                  setDate={(expiration) =>
                    setState((current) => ({ ...current, expiration }))
                  }
                  notRequired
                  allowPast={false}
                />
                <Textarea
                  label="Note"
                  value={state.comment}
                  setValue={(comment) => setState((current) => ({ ...current, comment }))}
                  placeholder="Why this key is needed"
                  rows={3}
                  disabled={disabled}
                />
              </VStack>
            </VStack>
          </form>
        </SlideOver.Body>

        <SlideOver.Footer>
          <ConfirmationDialog
            confirmationQuestion="Delete this key?"
            description="Assigned Macs will stop allowing this address through this key."
            trigger={
              <Button
                type="button"
                variant="destructive"
                icon={TrashIcon}
                onClick={() => {}}
                disabled={disabled}
              >
                Delete
              </Button>
            }
            actions={[
              { text: `Cancel`, variant: `ghost` },
              {
                text: `Delete key`,
                variant: `destructive`,
                icon: TrashIcon,
                loading: deleting,
                onClick: () =>
                  onDelete().then(
                    () => onOpenChange(false),
                    () => undefined,
                  ),
              },
            ]}
          />
          <Spacer />
          <Button
            type="button"
            variant="ghost"
            onClick={() => onOpenChange(false)}
            disabled={disabled}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            form={formId}
            variant="primary"
            icon={KeyRoundIcon}
            disabled={!key || disabled}
            loading={saving}
          >
            Save changes
          </Button>
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export const CreateKeySlideOver: React.FC<Props> = ({
  open,
  apps,
  saving,
  onOpenChange,
  onSave,
}) => {
  const formId = React.useId();
  const targetInputId = React.useId();
  const [state, setState] = React.useState<KeyEditorState>(newKeyEditorState);
  const [stage, setStage] = React.useState<EditorStage>(`target`);
  const [hasReachedReview, setHasReachedReview] = React.useState(false);
  const [showExpiration, setShowExpiration] = React.useState(false);
  const [showNote, setShowNote] = React.useState(false);

  React.useEffect(() => {
    if (!open) {
      return;
    }
    setState(newKeyEditorState());
    setStage(`target`);
    setHasReachedReview(false);
    setShowExpiration(false);
    setShowNote(false);
  }, [open]);

  const key = keyFromEditorState(state);
  const targetKey = keyFromEditorState({ ...state, scopeType: `webBrowsers` });
  const error = keyEditorError(state);
  const warning = broadAccessWarning(state);
  const normalizedAppBundleId = state.appBundleId
    .trim()
    .replace(/^\./, ``)
    .replace(/^[A-Z0-9]{10}\./, ``);
  const previewAppName =
    state.scopeType !== `singleApp`
      ? undefined
      : state.appIdentificationType === `identifiedAppSlug`
        ? apps.find((app) => app.slug === state.appSlug)?.name
        : apps.find((app) => app.bundleId === normalizedAppBundleId)?.name;
  const previewRecord = key
    ? {
        key,
        comment: state.comment.trim() || undefined,
        expiration: state.expiration?.toISOString(),
        appName: previewAppName,
      }
    : null;

  const changeTargetType = (targetType: KeyTargetType): void => {
    setState((current) => ({
      ...current,
      targetType,
      address: targetType === current.targetType ? current.address : ``,
      domainMatch: `standard`,
      matchingOverridden: false,
    }));
  };

  const changeAddress = (address: string): void => {
    setState((current) => ({
      ...current,
      address,
      domainMatch:
        current.targetType === `website` && !current.matchingOverridden
          ? inferredDomainMatch(address)
          : current.domainMatch,
    }));
  };

  const changeMatching = (domainMatch: DomainMatchType): void => {
    setState((current) => ({
      ...current,
      domainMatch,
      matchingOverridden: true,
    }));
  };

  const changeScope = (scopeType: KeyScopeType): void => {
    setState((current) => ({ ...current, scopeType }));
  };

  const changeAppIdentificationType = (
    appIdentificationType: AppIdentificationType,
  ): void => {
    setState((current) => ({ ...current, appIdentificationType }));
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();

    if (stage === `target`) {
      if (!targetKey) {
        return;
      }
      setStage(hasReachedReview ? `review` : `scope`);
      return;
    }

    if (stage === `scope`) {
      if (!key) {
        return;
      }
      setHasReachedReview(true);
      setStage(`review`);
      return;
    }

    if (!key || saving) {
      return;
    }

    const comment = state.comment.trim();
    void onSave({
      key,
      comment: comment || undefined,
      expiration: state.expiration,
    }).then(
      () => onOpenChange(false),
      () => undefined,
    );
  };

  const handleFormKeyDown = (event: React.KeyboardEvent<HTMLFormElement>): void => {
    if (
      stage === `scope` &&
      event.key === `Enter` &&
      event.target instanceof HTMLInputElement &&
      event.target.type === `radio`
    ) {
      event.preventDefault();
      event.currentTarget.requestSubmit();
    }
  };

  const returnFromTarget = (): void => {
    if (hasReachedReview) {
      setStage(`review`);
    } else {
      onOpenChange(false);
    }
  };

  const returnFromScope = (): void => {
    setStage(`target`);
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={onOpenChange}
      ariaLabel="Add key"
      heading="Add a key"
      subheading="Set what to allow and where it should work."
      size="large"
      dismissible={!saving}
    >
      <VStack className="h-full">
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          <form id={formId} onSubmit={handleSubmit} onKeyDown={handleFormKeyDown}>
            <VStack gap={5}>
              <FlowProgress stage={stage} />

              {stage === `target` && (
                <TargetEditor
                  state={state}
                  inputId={targetInputId}
                  error={error}
                  warning={warning}
                  disabled={saving}
                  changeTargetType={changeTargetType}
                  changeAddress={changeAddress}
                  changeMatching={changeMatching}
                />
              )}

              {stage === `scope` && (
                <ScopeEditor
                  state={state}
                  apps={apps}
                  disabled={saving}
                  changeScope={changeScope}
                  changeAppIdentificationType={changeAppIdentificationType}
                  changeAppSlug={(appSlug) =>
                    setState((current) => ({ ...current, appSlug }))
                  }
                  changeAppBundleId={(appBundleId) =>
                    setState((current) => ({ ...current, appBundleId }))
                  }
                />
              )}

              {stage === `review` && (
                <VStack gap={4}>
                  <StageIntro
                    title="Ready to add this key?"
                    description="Check the key below before adding it."
                  />

                  {previewRecord && (
                    <Card padding={0} className="overflow-hidden">
                      <KeyDisplay record={previewRecord} alwaysShowLabels />
                    </Card>
                  )}

                  {warning && <Banner variant="warning">{warning}</Banner>}

                  <VStack gap={4}>
                    <VStack gap={0.5}>
                      <Text as="h3" variant="bodyLargeStrong">
                        Anything else?
                      </Text>
                      <Text variant="captionSubtle" className="leading-5">
                        Expiration and notes are optional. Skip them unless they help you
                        manage this key.
                      </Text>
                    </VStack>

                    {(!showExpiration || !showNote) && (
                      <HStack wrap gap={2}>
                        {!showExpiration && (
                          <Button
                            type="button"
                            variant="default"
                            size="small"
                            icon={ClockIcon}
                            onClick={() => setShowExpiration(true)}
                          >
                            Add expiration
                          </Button>
                        )}
                        {!showNote && (
                          <Button
                            type="button"
                            variant="default"
                            size="small"
                            icon={FileTextIcon}
                            onClick={() => setShowNote(true)}
                          >
                            Add note
                          </Button>
                        )}
                      </HStack>
                    )}

                    {showExpiration && (
                      <DateTimePicker
                        label="Expiration"
                        date={state.expiration}
                        setDate={(expiration) =>
                          setState((current) => ({ ...current, expiration }))
                        }
                        notRequired
                        allowPast={false}
                      />
                    )}

                    {showNote && (
                      <Textarea
                        label="Note"
                        value={state.comment}
                        setValue={(comment) =>
                          setState((current) => ({ ...current, comment }))
                        }
                        placeholder="Why this key is needed"
                        rows={3}
                      />
                    )}
                  </VStack>
                </VStack>
              )}
            </VStack>
          </form>
        </SlideOver.Body>

        <SlideOver.Footer>
          {stage === `target` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={hasReachedReview ? ArrowLeftIcon : undefined}
                onClick={returnFromTarget}
                disabled={saving}
              >
                {hasReachedReview ? `Back to review` : `Cancel`}
              </Button>
              <Spacer />
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={ArrowRightIcon}
                iconPosition="right"
                disabled={!targetKey || saving}
              >
                {hasReachedReview ? `Review changes` : `Continue`}
              </Button>
            </>
          )}

          {stage === `scope` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={ArrowLeftIcon}
                onClick={returnFromScope}
                disabled={saving}
              >
                Back
              </Button>
              <Spacer />
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={ArrowRightIcon}
                iconPosition="right"
                disabled={!key || saving}
              >
                {hasReachedReview ? `Review changes` : `Review key`}
              </Button>
            </>
          )}

          {stage === `review` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={ArrowLeftIcon}
                onClick={() => setStage(`scope`)}
                disabled={saving}
              >
                Back
              </Button>
              <Spacer />
              <Button
                type="button"
                variant="ghost"
                onClick={() => onOpenChange(false)}
                disabled={saving}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={KeyRoundIcon}
                disabled={!key || saving}
                loading={saving}
              >
                Add key
              </Button>
            </>
          )}
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export default CreateKeySlideOver;
