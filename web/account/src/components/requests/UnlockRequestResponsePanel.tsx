import {
  Button,
  Card,
  DateTimePicker,
  HStack,
  Input,
  Select,
  type SelectOption,
  Stack,
  Text,
  Toggle,
  VStack,
  inflect,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  AsteriskIcon,
  ChevronRightIcon,
  GlobeIcon,
  LayoutGridIcon,
  ShieldIcon,
} from 'lucide-react';
import React from 'react';
import type {
  KeyAddressType,
  KeyScopeType,
  UnlockKey,
  UnlockRequestKeyDraft,
} from '#/components/types';

interface Props {
  domains: string[];
  keychainOptions: Array<{ id: string; name: string }>;
  onDenyAll: () => void;
  onSave: (keys: UnlockRequestKeyDraft[]) => void;
}

const addressTypeOptions: Array<SelectOption<KeyAddressType>> = [
  {
    value: `standard`,
    label: `Standard`,
    description: `Matches any subdomain`,
    icon: AsteriskIcon,
  },
  {
    value: `strict`,
    label: `Strict`,
    description: `Matches only the exact domain`,
    icon: ShieldIcon,
  },
];

const unlockedForOptions: Array<SelectOption<KeyScopeType>> = [
  {
    value: `allApps`,
    label: `All apps`,
    description: `Unlocked for all apps`,
    icon: LayoutGridIcon,
  },
  {
    value: `webBrowsers`,
    label: `Web browsers`,
    description: `Unlocked just for web browsers (Chrome, Safari, Firefox, etc.)`,
    icon: GlobeIcon,
  },
];

export const defaultKeyFromDomain = (domain: string): UnlockKey => ({
  domain,
  addressType: `standard`,
  scope: { type: `webBrowsers` },
});

const UnlockRequestResponsePanel: React.FC<Props> = ({
  domains,
  keychainOptions,
  onDenyAll,
  onSave,
}) => {
  const defaultKeychainId = keychainOptions[0]?.id ?? ``;
  const [keys, setKeys] = React.useState<UnlockRequestKeyDraft[]>(
    domains.map((domain) => ({
      id: domain,
      allowed: true,
      key: defaultKeyFromDomain(domain),
      moreOptionsExpanded: false,
      keychainId: defaultKeychainId,
    })),
  );

  React.useEffect(() => {
    setKeys(
      domains.map((domain) => ({
        id: domain,
        allowed: true,
        key: defaultKeyFromDomain(domain),
        moreOptionsExpanded: false,
        keychainId: defaultKeychainId,
      })),
    );
  }, [domains, defaultKeychainId]);

  const updateKeyAddressType = (domain: string, addressType: KeyAddressType): void => {
    setKeys((currentKeys) =>
      currentKeys.map((keyDraft) =>
        keyDraft.key.domain === domain
          ? { ...keyDraft, key: { ...keyDraft.key, addressType } }
          : keyDraft,
      ),
    );
  };

  const updateKeyUnlockedFor = (domain: string, unlockedFor: KeyScopeType): void => {
    setKeys((currentKeys) =>
      currentKeys.map((keyDraft) =>
        keyDraft.key.domain === domain
          ? {
              ...keyDraft,
              key: { ...keyDraft.key, scope: { type: unlockedFor, bundleId: `` } },
            }
          : keyDraft,
      ),
    );
  };

  const allowedKeysCount = keys.filter((keyDraft) => keyDraft.allowed).length;
  const keychainSelectOptions = keychainOptions.map((keychain) => ({
    value: keychain.id,
    label: keychain.name,
  }));

  return (
    <VStack
      justify="between"
      gap={8}
      className="h-full w-full px-3 @lg/slide:px-6 pb-3 @lg/slide:pb-6 overflow-scroll"
    >
      <div>
        <Card
          padding={0}
          className="border-y @lg/slide:border-x -mx-3 @lg/slide:mx-0 @lg/slide:rounded-xl"
        >
          <VStack>
            {keys.map((keyDraft) => (
              <VStack
                key={keyDraft.key.domain}
                gap={2}
                className="py-5 px-3 border-b border-stone-200 last:border-b-0"
              >
                <HStack justify="between" gap={2}>
                  <Text
                    variant="bodyStrong"
                    className={cx(!keyDraft.allowed && `opacity-30 line-through`)}
                  >
                    {keyDraft.key.domain}
                  </Text>
                  <Toggle
                    checked={keyDraft.allowed}
                    setChecked={() => {
                      setKeys((currentKeys) =>
                        currentKeys.map((currentKeyDraft) =>
                          currentKeyDraft.key.domain === keyDraft.key.domain
                            ? {
                                ...currentKeyDraft,
                                allowed: !currentKeyDraft.allowed,
                              }
                            : currentKeyDraft,
                        ),
                      );
                    }}
                  />
                </HStack>
                <VStack gap={3} className={cx(!keyDraft.allowed && `hidden`)}>
                  <HStack gap={4}>
                    <Select
                      label="Which keychain:"
                      labelPosition="left"
                      selected={keyDraft.keychainId}
                      setSelected={(keychainId) =>
                        setKeys((currentKeys) =>
                          currentKeys.map((currentKeyDraft) =>
                            currentKeyDraft.key.domain === keyDraft.key.domain
                              ? { ...currentKeyDraft, keychainId }
                              : currentKeyDraft,
                          ),
                        )
                      }
                      possibleValues={keychainSelectOptions}
                      size="small"
                    />
                  </HStack>
                  <VStack
                    className={cx(
                      `border-y border-x border-stone-200 bg-stone-50 shadow shadow-stone-300/30 rounded-xl transition-[margin,border-radius] duration-150`,
                      keyDraft.moreOptionsExpanded &&
                        `!border-x-0 @lg/slide:!border-x !rounded-none @lg/slide:!rounded-xl -mx-3 @lg/slide:mx-0`,
                    )}
                  >
                    <HStack
                      as="button"
                      type="button"
                      justify="between"
                      className="cursor-pointer py-2 px-3"
                      onClick={() =>
                        setKeys((currentKeys) =>
                          currentKeys.map((currentKeyDraft) =>
                            currentKeyDraft.key.domain === keyDraft.key.domain
                              ? {
                                  ...currentKeyDraft,
                                  moreOptionsExpanded:
                                    !currentKeyDraft.moreOptionsExpanded,
                                }
                              : currentKeyDraft,
                          ),
                        )
                      }
                    >
                      <Text variant="bodySubtle">More options</Text>
                      <ChevronRightIcon
                        className={cx(
                          `h-4 w-4 text-stone-500 transition-[rotate] duration-150`,
                          keyDraft.moreOptionsExpanded && `rotate-90`,
                        )}
                      />
                    </HStack>
                    <div
                      className={cx(
                        keyDraft.moreOptionsExpanded ? `h-auto` : `h-0`,
                        `overflow-hidden transition-[height] duration-150`,
                      )}
                    >
                      <VStack
                        gap={3}
                        className={cx(
                          `p-3 transition-opacity druation-150`,
                          !keyDraft.moreOptionsExpanded && `opacity-0`,
                        )}
                      >
                        <Stack
                          direction={{ default: `vertical`, '@md/slide': `horizontal` }}
                          gap={{ default: 3, '@md/slide': 2 }}
                        >
                          <Select
                            label="Address type:"
                            selected={keyDraft.key.addressType}
                            setSelected={(addressType) =>
                              updateKeyAddressType(keyDraft.key.domain, addressType)
                            }
                            possibleValues={addressTypeOptions}
                            className="@md/slide:w-1/2"
                          />
                          <Select
                            label="Unlocked for:"
                            selected={keyDraft.key.scope.type}
                            setSelected={(unlockedFor) =>
                              updateKeyUnlockedFor(keyDraft.key.domain, unlockedFor)
                            }
                            possibleValues={unlockedForOptions}
                            className="@md/slide:w-1/2"
                          />
                        </Stack>
                        <Stack
                          direction={{ default: `vertical`, '@md/slide': `horizontal` }}
                          gap={{ default: 3, '@md/slide': 2 }}
                        >
                          <Input
                            label="Note"
                            placeholder="Optional note..."
                            type="text"
                            value={keyDraft.key.note ?? ``}
                            setValue={(value) => {
                              setKeys((currentKeys) =>
                                currentKeys.map((currentKeyDraft) =>
                                  currentKeyDraft.key.domain === keyDraft.key.domain
                                    ? {
                                        ...currentKeyDraft,
                                        key: { ...currentKeyDraft.key, note: value },
                                      }
                                    : currentKeyDraft,
                                ),
                              );
                            }}
                            className="@md/slide:w-1/2"
                          />
                          <DateTimePicker
                            date={keyDraft.key.expiration}
                            notRequred
                            setDate={(date) => {
                              setKeys((currentKeys) =>
                                currentKeys.map((currentKeyDraft) =>
                                  currentKeyDraft.key.domain === keyDraft.key.domain
                                    ? {
                                        ...currentKeyDraft,
                                        key: {
                                          ...currentKeyDraft.key,
                                          expiration: date,
                                        },
                                      }
                                    : currentKeyDraft,
                                ),
                              );
                            }}
                            label="Expiration date"
                            className="@md/slide:w-1/2"
                          />
                        </Stack>
                      </VStack>
                    </div>
                  </VStack>
                </VStack>
              </VStack>
            ))}
          </VStack>
        </Card>
      </div>
      <HStack justify="end" gap={2}>
        <Button type="button" onClick={onDenyAll} variant="ghost">
          Deny all
        </Button>
        <Button
          type="button"
          onClick={() => onSave(keys)}
          variant="primary"
          disabled={allowedKeysCount === 0}
        >
          Save {allowedKeysCount} {inflect(`key`, allowedKeysCount)}
        </Button>
      </HStack>
    </VStack>
  );
};

export default UnlockRequestResponsePanel;
