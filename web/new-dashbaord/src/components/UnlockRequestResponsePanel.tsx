import {
  Button,
  DateTimePicker,
  Input,
  Select,
  type SelectOption,
  Toggle,
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
import React, { useState } from 'react';
import { type Key, defaultKeyFromDomain } from '#/lib/mock-data';

interface Props {
  domains: string[];
  personName: string;
}

const addressTypeOptions: Array<SelectOption<Key[`addressType`]>> = [
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

const unlockedForOptions: Array<SelectOption<Key[`scope`][`type`]>> = [
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

const keyChainOptions = [`School stuff`, `Games`, `Music`, `Jimmy's stuff`] as const;

const UnlockRequstResponsePanel: React.FC<Props> = ({ domains, personName }) => {
  const [keys, setKeys] = useState<
    Array<{
      allowed: boolean;
      key: Key;
      moreOptionsExpanded: boolean;
      keyChain: (typeof keyChainOptions)[number];
    }>
  >(
    domains.map((d) => ({
      allowed: true,
      key: defaultKeyFromDomain(d),
      moreOptionsExpanded: false,
      keyChain: `School stuff`,
    })),
  );

  const updateKeyAddressType = (
    domain: string,
    addressType: Key[`addressType`],
  ): void => {
    setKeys((currentKeys) =>
      currentKeys.map((k) =>
        k.key.domain === domain ? { ...k, key: { ...k.key, addressType } } : k,
      ),
    );
  };

  const updateKeyUnlockedFor = (
    domain: string,
    unlockedFor: Key[`scope`][`type`],
  ): void => {
    setKeys((currentKeys) =>
      currentKeys.map((k) =>
        k.key.domain === domain
          ? { ...k, key: { ...k.key, scope: { type: unlockedFor, bundleId: `` } } }
          : k,
      ),
    );
  };

  const allowedKeysCount = keys.filter((k) => k.allowed).length;
  return (
    <div className="h-full w-full flex flex-col px-3 @lg/slide:px-6 pb-3 @lg/slide:pb-6 pt-6 @lg/slide:pt-8 justify-between overflow-scroll gap-8">
      <div>
        <h2 className="text-xl font-medium">Create keys for {personName}</h2>
        <p className="text-sm text-stone-600 mt-2">
          We pre-filled some sensible defaults for you, but make sure to check that
          everything looks good before saving!
        </p>
        <div className="flex flex-col mt-4 border-y @lg/slide:border-x border-stone-200 bg-white -mx-3 @lg/slide:mx-0 px-3 @lg/slide:rounded-xl shadow shadow-stone-300/30">
          {keys.map((k) => (
            <div
              key={k.key.domain}
              className="py-5 flex flex-col border-b border-stone-200 gap-2 last:border-b-0"
            >
              <div className="flex justify-between items-center gap-2">
                <span
                  className={cx(
                    `font-medium text-stone-800`,
                    !k.allowed && `opacity-30 line-through`,
                  )}
                >
                  {k.key.domain}
                </span>
                <Toggle
                  checked={k.allowed}
                  setChecked={() => {
                    setKeys((currentKeys) =>
                      currentKeys.map((k2) =>
                        k2.key.domain === k.key.domain
                          ? { ...k2, allowed: !k2.allowed }
                          : k2,
                      ),
                    );
                  }}
                />
              </div>
              <div className={cx(`flex flex-col gap-3`, !k.allowed && `hidden`)}>
                <div className="flex items-center gap-4">
                  <Select
                    label="Which keychain:"
                    labelPosition="left"
                    selected={k.keyChain}
                    setSelected={(addressType) =>
                      setKeys((currentKeys) =>
                        currentKeys.map((k2) =>
                          k2.key.domain === k.key.domain
                            ? { ...k2, keyChain: addressType }
                            : k2,
                        ),
                      )
                    }
                    possibleValues={keyChainOptions}
                    size="small"
                  />
                </div>
                <div
                  className={cx(
                    `flex flex-col border-y border-x border-stone-200 bg-stone-50 shadow shadow-stone-300/30 rounded-xl transition-[margin,border-radius] duration-150`,
                    k.moreOptionsExpanded &&
                      `!border-x-0 @lg/slide:!border-x !rounded-none @lg/slide:!rounded-xl -mx-3 @lg/slide:mx-0`,
                  )}
                >
                  <button
                    className="flex justify-between items-center cursor-pointer py-2 px-3"
                    onClick={() =>
                      setKeys((currentKeys) =>
                        currentKeys.map((k2) =>
                          k2.key.domain === k.key.domain
                            ? { ...k2, moreOptionsExpanded: !k2.moreOptionsExpanded }
                            : k2,
                        ),
                      )
                    }
                  >
                    <span className="text-sm text-stone-600">More options</span>
                    <ChevronRightIcon
                      className={cx(
                        `h-4 w-4 text-stone-500 transition-[rotate] duration-150`,
                        k.moreOptionsExpanded && `rotate-90`,
                      )}
                    />
                  </button>
                  <div
                    className={cx(
                      k.moreOptionsExpanded ? `h-auto` : `h-0`,
                      `overflow-hidden transition-[height] duration-150`,
                    )}
                  >
                    <div
                      className={cx(
                        `p-3 transition-opacity druation-150 flex flex-col gap-3`,
                        !k.moreOptionsExpanded && `opacity-0`,
                      )}
                    >
                      <div className="flex flex-col @md/slide:flex-row gap-3 @md/slide:gap-2">
                        <Select
                          label="Address type:"
                          selected={k.key.addressType}
                          setSelected={(addressType) =>
                            updateKeyAddressType(k.key.domain, addressType)
                          }
                          possibleValues={addressTypeOptions}
                          className="@md/slide:w-1/2"
                        />
                        <Select
                          label="Unlocked for:"
                          selected={k.key.scope.type}
                          setSelected={(unlockedFor) =>
                            updateKeyUnlockedFor(k.key.domain, unlockedFor)
                          }
                          possibleValues={unlockedForOptions}
                          className="@md/slide:w-1/2"
                        />
                      </div>
                      <div className="flex flex-col @md/slide:flex-row gap-3 @md/slide:gap-2">
                        <Input
                          label="Note"
                          placeholder="Optional note..."
                          type="text"
                          value={k.key.note ?? ``}
                          setValue={(value) => {
                            setKeys((currentKeys) =>
                              currentKeys.map((k2) =>
                                k2.key.domain === k.key.domain
                                  ? { ...k2, key: { ...k2.key, note: value } }
                                  : k2,
                              ),
                            );
                          }}
                          className="@md/slide:w-1/2"
                        />
                        <DateTimePicker
                          date={k.key.expiration}
                          notRequred
                          setDate={(date) => {
                            setKeys((currentKeys) =>
                              currentKeys.map((k2) =>
                                k2.key.domain === k.key.domain
                                  ? { ...k2, key: { ...k2.key, expiration: date } }
                                  : k2,
                              ),
                            );
                          }}
                          label="Expiration date"
                          className="@md/slide:w-1/2"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <div className="flex justify-end gap-2">
        <Button type="button" onClick={() => {}} variant="ghost">
          Deny all
        </Button>
        <Button
          type="button"
          onClick={() => {}}
          variant="primary"
          disabled={allowedKeysCount === 0}
        >
          Save {allowedKeysCount} {inflect(`key`, allowedKeysCount)}
        </Button>
      </div>
    </div>
  );
};

export default UnlockRequstResponsePanel;
