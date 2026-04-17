import { Button } from '@shared/components';
import React, { useContext } from 'react';
import type { DiscoveredApp } from '../onboarding-store';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';
import {
  AppIcon,
  ScrollableAppGrid,
  Tile,
  type TileTheme,
  useToggleSet,
} from './AppGridShared';

const theme: TileTheme = {
  activeBorder: `border-red-400`,
  activeBg: `bg-red-50/60`,
  activeNameClass: `text-slate-400 line-through`,
  activeBadgeClass: `bg-red-500 text-white`,
  activeLabel: `Blocked`,
  activeIconClass: `grayscale opacity-40`,
  inactiveBadgeClass: `bg-fuchsia-100 text-fuchsia-600`,
  inactiveLabel: `Allowed`,
};

interface Props {
  apps: DiscoveredApp[];
  childName?: string;
}

const BlockApps: React.FC<Props> = ({ apps, childName }) => {
  const { emit } = useContext(OnboardingContext);
  const [blockedIds, toggle] = useToggleSet();

  return (
    <div className="h-full flex flex-row pt-20 pb-10 pl-10 pr-4 gap-8">
      <div className="flex flex-col justify-center w-[320px] flex-shrink-0">
        <Onboarding.Heading>Block apps you don&rsquo;t want used</Onboarding.Heading>
        <Onboarding.Text className="mt-4">
          Any apps that {childName ? <b>{childName}</b> : `your child`} should{` `}
          <b>never have access to?</b> Tap to block them completely&mdash;they won&rsquo;t
          be able to open at all.
        </Onboarding.Text>
        <Onboarding.Text className="mt-3 text-sm !text-slate-400">
          You can always change this later from the parent dashboard.
        </Onboarding.Text>
        <div className="mt-8">
          <Button
            type="button"
            color="primary"
            size="large"
            className="w-full"
            onClick={() =>
              emit({
                case: `blockedAppsSelected`,
                bundleIds: [...blockedIds],
              })
            }
            tabIndex={-1}
          >
            {blockedIds.size > 0
              ? `Block (${blockedIds.size}) app${blockedIds.size === 1 ? `` : `s`}`
              : `Next`}
            <i className="fa-solid fa-arrow-right ml-3" />
          </Button>
        </div>
      </div>
      <ScrollableAppGrid>
        {apps.map((app) => (
          <Tile
            key={app.bundleId}
            id={app.bundleId}
            name={app.name}
            icon={<AppIcon app={app} />}
            active={blockedIds.has(app.bundleId)}
            theme={theme}
            onToggle={toggle}
          />
        ))}
      </ScrollableAppGrid>
    </div>
  );
};

export default BlockApps;
