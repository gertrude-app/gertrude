import {
  Badge,
  Button,
  EmptyState,
  Input,
  SlideOver,
  Tooltip,
  inflect,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, KeyIcon } from 'lucide-react';
import React from 'react';
import type { Keychain } from '#/components/types';

type KeychainTab = `own` | `public`;

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  personName: string;
  keychains: Keychain[];
  assignedKeychainIds: string[];
  onAdd: (keychainIds: string[]) => void;
};

const AddKeychainSlideOver: React.FC<Props> = ({
  open,
  onOpenChange,
  personName,
  keychains,
  assignedKeychainIds,
  onAdd,
}) => {
  const [selectedKeychainIds, setSelectedKeychainIds] = React.useState<string[]>([]);
  const [searchQuery, setSearchQuery] = React.useState(``);
  const [tab, setTab] = React.useState<KeychainTab>(`own`);
  const normalizedSearchQuery = searchQuery.trim().toLowerCase();
  const tabKeychains = keychains.filter((keychain) =>
    tab === `public` ? keychain.isPublic : !keychain.isPublic,
  );
  const filteredKeychains = tabKeychains.filter((keychain) =>
    keychain.name.toLowerCase().includes(normalizedSearchQuery),
  );
  const selectedKeychains = keychains.filter((keychain) =>
    selectedKeychainIds.includes(keychain.id),
  );
  const ownKeychainCount = keychains.filter((keychain) => !keychain.isPublic).length;
  const publicKeychainCount = keychains.filter((keychain) => keychain.isPublic).length;

  const reset = (): void => {
    setSelectedKeychainIds([]);
    setSearchQuery(``);
    setTab(`own`);
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

  return (
    <SlideOver
      open={open}
      onOpenChange={handleOpenChange}
      ariaLabel={`Add keychains to ${personName}`}
      heading="Add keychains"
      subheading={`Choose keychains to assign to ${personName}.`}
      size="large"
    >
      <div className="flex h-full flex-col">
        <div className="flex shrink-0 flex-col gap-3 px-3 pb-4 @lg/slide:px-6">
          <Input
            type="text"
            value={searchQuery}
            setValue={setSearchQuery}
            placeholder="Search keychains..."
          />
          <div className="grid grid-cols-2 rounded-xl bg-stone-100 p-1.5">
            {(
              [
                [`own`, `Your Keychains`, ownKeychainCount],
                [`public`, `Public Keychains`, publicKeychainCount],
              ] as const
            ).map(([value, label, count]) => (
              <button
                key={value}
                type="button"
                onClick={() => setTab(value)}
                className={cx(
                  `flex items-center justify-center gap-2 rounded-lg border px-3 py-1.5 text-sm font-medium transition-[background-color,border-color,box-shadow,color] duration-100`,
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
              </button>
            ))}
          </div>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4 @lg/slide:px-6">
          {filteredKeychains.length > 0 ? (
            <div className="grid grid-cols-1 gap-2 @md/slide:grid-cols-2">
              {filteredKeychains.map((keychain) => {
                const selected = selectedKeychainIds.includes(keychain.id);
                const alreadyAssigned = assignedKeychainIds.includes(keychain.id);
                const keychainButton = (
                  <button
                    key={keychain.id}
                    type="button"
                    disabled={alreadyAssigned}
                    aria-pressed={selected}
                    onClick={() => toggleKeychain(keychain)}
                    className={cx(
                      `relative flex min-h-34 w-full flex-col rounded-xl border p-3 text-left shadow transition-[background-color,border-color,box-shadow,opacity] duration-150`,
                      alreadyAssigned
                        ? `cursor-not-allowed border-stone-200 bg-stone-100/70 opacity-60 shadow-transparent`
                        : selected
                          ? `cursor-pointer border-violet-300 bg-violet-50 shadow-violet-300/30 hover:border-violet-400 hover:shadow-violet-300/50`
                          : `cursor-pointer border-stone-200 bg-white shadow-stone-300/30 hover:border-stone-400/70 hover:shadow-stone-300/70`,
                    )}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-2">
                          <span className="font-medium text-stone-900">
                            {keychain.name}
                          </span>
                          {keychain.isPublic && <Badge size="small">Public</Badge>}
                        </div>
                        {keychain.description && (
                          <span className="mt-1 line-clamp-2 text-sm text-stone-600">
                            {keychain.description}
                          </span>
                        )}
                      </div>
                      {selected && !alreadyAssigned && (
                        <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30">
                          <CheckIcon className="h-3 w-3" strokeWidth={3} />
                        </span>
                      )}
                    </div>
                    <div className="mt-auto flex items-center justify-between gap-3 pt-4">
                      <span className="text-xs font-medium text-stone-500">
                        {keychain.numKeys} {inflect(`key`, keychain.numKeys)}
                      </span>
                      {alreadyAssigned && (
                        <span className="rounded-full bg-stone-200 px-2 py-0.5 text-xs font-medium text-stone-600">
                          Already added
                        </span>
                      )}
                    </div>
                  </button>
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
        </div>
        <div className="flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-3 py-3 @lg/slide:px-6 @lg/slide:py-4">
          <span className="text-sm text-stone-600">
            {selectedKeychains.length === 0
              ? `Select one or more keychains`
              : `${selectedKeychains.length} ${inflect(
                  `keychain`,
                  selectedKeychains.length,
                )} selected`}
          </span>
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
        </div>
      </div>
    </SlideOver>
  );
};

export default AddKeychainSlideOver;
