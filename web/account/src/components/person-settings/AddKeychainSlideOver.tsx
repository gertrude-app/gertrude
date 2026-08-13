import {
  Badge,
  Button,
  Card,
  EmptyState,
  HStack,
  Input,
  SlideOver,
  Text,
  Textarea,
  Tooltip,
  VStack,
  inflect,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, KeyIcon, ShieldAlertIcon } from 'lucide-react';
import React from 'react';
import type { Keychain } from '#/components/types';

type KeychainTab = `own` | `public`;
type SelectableKeychain = Keychain & { isOwn?: boolean };

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  personName: string;
  keychains: SelectableKeychain[];
  assignedKeychainIds: string[];
  onAdd: (keychainIds: string[]) => void;
  onRequestPublicKeychain?: (input: {
    searchQuery: string;
    description: string;
  }) => Promise<void>;
  defaultTab?: KeychainTab;
  defaultSearchQuery?: string;
};

const AddKeychainSlideOver: React.FC<Props> = ({
  open,
  onOpenChange,
  personName,
  keychains,
  assignedKeychainIds,
  onAdd,
  onRequestPublicKeychain,
  defaultTab = `own`,
  defaultSearchQuery = ``,
}) => {
  const [selectedKeychainIds, setSelectedKeychainIds] = React.useState<string[]>([]);
  const [searchQuery, setSearchQuery] = React.useState(defaultSearchQuery);
  const [tab, setTab] = React.useState<KeychainTab>(defaultTab);
  const [requestDescription, setRequestDescription] = React.useState(``);
  const [requestState, setRequestState] = React.useState<
    `idle` | `submitting` | `succeeded` | `failed`
  >(`idle`);
  const normalizedSearchQuery = searchQuery.trim().toLowerCase();
  const isOwnKeychain = (keychain: SelectableKeychain): boolean =>
    keychain.isOwn ?? !keychain.isPublic;
  const tabKeychains = keychains.filter((keychain) =>
    tab === `public`
      ? keychain.isPublic && !isOwnKeychain(keychain)
      : isOwnKeychain(keychain),
  );
  const filteredKeychains = tabKeychains.filter(
    (keychain) =>
      keychain.name.toLowerCase().includes(normalizedSearchQuery) ||
      keychain.description?.toLowerCase().includes(normalizedSearchQuery),
  );
  const selectedKeychains = keychains.filter((keychain) =>
    selectedKeychainIds.includes(keychain.id),
  );
  const ownKeychainCount = keychains.filter(isOwnKeychain).length;
  const publicKeychainCount = keychains.filter(
    (keychain) => keychain.isPublic && !isOwnKeychain(keychain),
  ).length;
  const requestingPublicKeychain =
    tab === `public` &&
    normalizedSearchQuery.length > 0 &&
    filteredKeychains.length === 0 &&
    onRequestPublicKeychain !== undefined;

  const reset = (): void => {
    setSelectedKeychainIds([]);
    setSearchQuery(defaultSearchQuery);
    setTab(defaultTab);
    setRequestDescription(``);
    setRequestState(`idle`);
  };
  const handleOpenChange = (nextOpen: boolean): void => {
    if (!nextOpen) {
      reset();
    }

    onOpenChange(nextOpen);
  };
  const toggleKeychain = (keychain: Keychain): void => {
    if (assignedKeychainIds.includes(keychain.id)) {
      return;
    }

    setSelectedKeychainIds((currentIds) =>
      currentIds.includes(keychain.id)
        ? currentIds.filter((id) => id !== keychain.id)
        : [...currentIds, keychain.id],
    );
  };
  const addSelectedKeychains = (): void => {
    if (selectedKeychainIds.length === 0) {
      return;
    }

    onAdd(selectedKeychainIds);
    handleOpenChange(false);
  };
  const requestPublicKeychain = (): void => {
    const trimmedSearchQuery = searchQuery.trim();
    const description = requestDescription.trim();
    if (!onRequestPublicKeychain || !trimmedSearchQuery || !description) {
      return;
    }

    setRequestState(`submitting`);
    void onRequestPublicKeychain({
      searchQuery: trimmedSearchQuery,
      description,
    }).then(
      () => setRequestState(`succeeded`),
      () => setRequestState(`failed`),
    );
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={handleOpenChange}
      ariaLabel={`Add keychains to ${personName}`}
      heading="Add keychains"
      subheading={`Choose keychains to assign to ${personName}. You can set schedules after adding them.`}
      size="large"
    >
      <VStack className="h-full">
        <VStack gap={3} className="shrink-0 px-3 pb-4 @lg/slide:px-6">
          <Input
            type="text"
            value={searchQuery}
            setValue={(value) => {
              setSearchQuery(value);
              setRequestDescription(``);
              setRequestState(`idle`);
            }}
            placeholder="Search keychains..."
          />
          <div className="grid grid-cols-2 rounded-xl bg-stone-100 p-1.5">
            {(
              [
                [`own`, `Your Keychains`, ownKeychainCount],
                [`public`, `Public Keychains`, publicKeychainCount],
              ] as const
            ).map(([value, label, count]) => (
              <HStack
                as="button"
                key={value}
                type="button"
                justify="center"
                gap={2}
                onClick={() => {
                  setTab(value);
                  setRequestDescription(``);
                  setRequestState(`idle`);
                }}
                className={cx(
                  `rounded-lg border px-3 py-1.5 text-sm font-medium transition-[background-color,border-color,box-shadow,color] duration-100`,
                  tab === value
                    ? `border-stone-200 bg-white text-stone-900 shadow shadow-stone-300/30`
                    : `cursor-pointer border-transparent text-stone-600 hover:bg-stone-200/50`,
                )}
              >
                <span>{label}</span>
                <span
                  className={cx(
                    `min-w-5 rounded-full px-1.5 py-0.25 text-xs font-medium tabular-nums`,
                    tab === value
                      ? `bg-stone-100 text-stone-700`
                      : `bg-stone-200/70 text-stone-600`,
                  )}
                >
                  {count}
                </span>
              </HStack>
            ))}
          </div>
        </VStack>
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          {filteredKeychains.length > 0 ? (
            <div className="grid grid-cols-1 gap-2 @md/slide:grid-cols-2">
              {filteredKeychains.map((keychain) => {
                const selected = selectedKeychainIds.includes(keychain.id);
                const alreadyAssigned = assignedKeychainIds.includes(keychain.id);
                const keychainButton = (
                  <Card
                    as="button"
                    key={keychain.id}
                    type="button"
                    interactive
                    selected={selected}
                    disabled={alreadyAssigned}
                    aria-pressed={selected}
                    onClick={() => toggleKeychain(keychain)}
                    className="relative flex min-h-34 w-full flex-col text-left"
                  >
                    <HStack align="start" justify="between" gap={3}>
                      <VStack className="min-w-0">
                        <HStack wrap gap={2}>
                          <Text variant="bodyLargeStrong">{keychain.name}</Text>
                          {keychain.isPublic && <Badge size="small">Public</Badge>}
                        </HStack>
                        {keychain.description && (
                          <Text variant="bodySubtle" lineClamp={2} className="mt-1">
                            {keychain.description}
                          </Text>
                        )}
                        {keychain.warning && (
                          <HStack
                            align="start"
                            gap={2}
                            className="mt-3 rounded-lg border border-amber-300 bg-amber-100/70 p-2"
                          >
                            <ShieldAlertIcon className="mt-0.5 h-4 w-4 shrink-0 text-amber-700" />
                            <Text variant="caption" className="leading-4 text-amber-900">
                              {keychain.warning}
                            </Text>
                          </HStack>
                        )}
                      </VStack>
                      {selected && !alreadyAssigned && (
                        <HStack
                          justify="center"
                          className="h-5 w-5 shrink-0 rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30"
                        >
                          <CheckIcon className="h-3 w-3" strokeWidth={3} />
                        </HStack>
                      )}
                    </HStack>
                    <HStack justify="between" gap={3} className="mt-auto pt-4">
                      <Text variant="captionMuted">
                        {keychain.numKeys} {inflect(`key`, keychain.numKeys)}
                      </Text>
                      {alreadyAssigned && (
                        <Text
                          variant="captionSubtleStrong"
                          className="rounded-full bg-stone-200 px-2 py-0.5"
                        >
                          Already added
                        </Text>
                      )}
                    </HStack>
                  </Card>
                );

                return alreadyAssigned ? (
                  <Tooltip
                    key={keychain.id}
                    content="This keychain is already assigned."
                    side="top"
                  >
                    <span className="block h-full">{keychainButton}</span>
                  </Tooltip>
                ) : (
                  keychainButton
                );
              })}
            </div>
          ) : requestingPublicKeychain ? (
            requestState === `succeeded` ? (
              <EmptyState
                icon={CheckIcon}
                title="Request Received"
                description="We'll review your request and follow up if we need more information."
              />
            ) : (
              <VStack gap={4} className="mt-2">
                <VStack gap={1}>
                  <Text variant="bodyLargeStrong">Request a Public Keychain</Text>
                  <Text variant="bodyMuted">
                    We couldn't find a public keychain matching “{searchQuery}.” Tell us
                    what you'd like it to allow.
                  </Text>
                </VStack>
                <Textarea
                  label="What are you looking for?"
                  value={requestDescription}
                  setValue={(value) => {
                    setRequestDescription(value);
                    if (requestState === `failed`) {
                      setRequestState(`idle`);
                    }
                  }}
                  placeholder="For example, websites and apps used by a specific curriculum…"
                  rows={3}
                  resize="vertical"
                  disabled={requestState === `submitting`}
                  error={
                    requestState === `failed`
                      ? `We couldn't submit your request. Please try again.`
                      : undefined
                  }
                />
                <HStack justify="end">
                  <Button
                    type="button"
                    variant="primary"
                    onClick={requestPublicKeychain}
                    disabled={!requestDescription.trim() || requestState === `submitting`}
                    loading={requestState === `submitting`}
                  >
                    Request Keychain
                  </Button>
                </HStack>
              </VStack>
            )
          ) : (
            <EmptyState
              icon={KeyIcon}
              title="No Keychains Found"
              description={
                normalizedSearchQuery
                  ? `No ${tab === `public` ? `public` : `personal`} keychains match “${searchQuery}”.`
                  : `No ${tab === `public` ? `public` : `personal`} keychains available.`
              }
            />
          )}
        </SlideOver.Body>
        {!requestingPublicKeychain && (
          <SlideOver.Footer>
            <Text variant="bodyMuted">
              {selectedKeychains.length === 0
                ? `Select one or more keychains`
                : `${selectedKeychains.length} ${inflect(
                    `keychain`,
                    selectedKeychains.length,
                  )} selected`}
            </Text>
            <Button
              type="button"
              variant="primary"
              disabled={selectedKeychains.length === 0}
              onClick={addSelectedKeychains}
            >
              {selectedKeychains.length === 0
                ? `Add Keychains`
                : `Add ${selectedKeychains.length} ${inflect(
                    `Keychain`,
                    selectedKeychains.length,
                  )}`}
            </Button>
          </SlideOver.Footer>
        )}
      </VStack>
    </SlideOver>
  );
};

export default AddKeychainSlideOver;
