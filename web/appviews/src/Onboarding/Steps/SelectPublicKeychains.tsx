import { Button } from '@shared/components';
import React, { useContext } from 'react';
import type { PublicKeychain } from '../onboarding-store';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';
import { ScrollableAppGrid, Tile, type TileTheme, useToggleSet } from './AppGridShared';

const theme: TileTheme = {
  activeBorder: `border-violet-400`,
  activeBg: `bg-violet-50/60`,
  activeNameClass: `text-violet-700`,
  activeBadgeClass: `bg-violet-500 text-white`,
  activeLabel: `Added`,
  inactiveBadgeClass: `bg-slate-100 text-slate-400`,
  inactiveLabel: `Tap to add`,
};

const ICON_COLORS = [
  `bg-rose-400`,
  `bg-amber-400`,
  `bg-emerald-400`,
  `bg-sky-400`,
  `bg-indigo-400`,
  `bg-fuchsia-400`,
  `bg-teal-400`,
  `bg-orange-400`,
];

function colorFor(seed: string): string {
  let hash = 0;
  for (let i = 0; i < seed.length; i++) {
    hash = (hash * 31 + seed.charCodeAt(i)) | 0;
  }
  return ICON_COLORS[Math.abs(hash) % ICON_COLORS.length] ?? `bg-slate-400`;
}

function initialsFor(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  const first = words[0] ?? ``;
  const second = words[1] ?? ``;
  if (!first) return `?`;
  if (!second) return first.slice(0, 2).toUpperCase();
  return `${first.charAt(0)}${second.charAt(0)}`.toUpperCase();
}

const KeychainIcon: React.FC<{ keychain: PublicKeychain }> = ({ keychain }) => (
  <div
    className={`w-full h-full flex items-center justify-center ${
      keychain.brandColor ? `` : colorFor(keychain.id)
    }`}
    style={keychain.brandColor ? { backgroundColor: keychain.brandColor } : undefined}
  >
    <span className="text-white text-base font-bold tracking-tight">
      {initialsFor(keychain.name)}
    </span>
  </div>
);

interface Props {
  keychains: PublicKeychain[];
}

const SelectPublicKeychains: React.FC<Props> = ({ keychains }) => {
  const { emit } = useContext(OnboardingContext);
  const [selectedIds, toggle] = useToggleSet();

  return (
    <div className="h-full flex flex-row pt-20 pb-10 pl-4 pr-10 gap-8">
      <ScrollableAppGrid>
        {keychains.map((keychain) => (
          <Tile
            key={keychain.id}
            id={keychain.id}
            name={keychain.name}
            icon={<KeychainIcon keychain={keychain} />}
            active={selectedIds.has(keychain.id)}
            theme={theme}
            onToggle={toggle}
          />
        ))}
      </ScrollableAppGrid>
      <div className="flex flex-col justify-center w-[320px] flex-shrink-0">
        <Onboarding.Heading>Add public keychains</Onboarding.Heading>
        <Onboarding.Text className="mt-4">
          Public keychains are created by Gertrude, and each one unlocks a widely-used
          website or service. Choose any that look useful. You can always add or remove
          keychains later from the parent dashboard.
        </Onboarding.Text>
        <div className="mt-8">
          <Button
            type="button"
            color="primary"
            size="large"
            className="w-full"
            onClick={() =>
              emit({
                case: `publicKeychainsSelected`,
                ids: [...selectedIds],
              })
            }
            tabIndex={-1}
          >
            {selectedIds.size > 0
              ? `Add (${selectedIds.size}) keychain${selectedIds.size === 1 ? `` : `s`}`
              : `Next`}
            <i className="fa-solid fa-arrow-right ml-3" />
          </Button>
        </div>
      </div>
    </div>
  );
};

export default SelectPublicKeychains;
