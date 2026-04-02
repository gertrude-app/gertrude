import { Button } from '@shared/components';
import React, { useContext } from 'react';
import type { DiscoveredApp } from '../onboarding-store';
import OnboardingContext from '../OnboardingContext';
import * as Onboarding from '../UtilityComponents';
import {
  AppTile,
  ScrollableAppGrid,
  type TileTheme,
  useToggleSet,
} from './AppGridShared';

const theme: TileTheme = {
  activeBorder: `border-emerald-400`,
  activeBg: `bg-emerald-50/60`,
  activeNameClass: `text-emerald-700`,
  activeBadgeClass: `bg-emerald-500 text-white`,
  activeLabel: `Unrestricted internet`,
  inactiveBadgeClass: `bg-slate-100 text-slate-400`,
  inactiveLabel: `No internet`,
};

interface Props {
  apps: DiscoveredApp[];
}

const AllowInternetApps: React.FC<Props> = ({ apps }) => {
  const { emit } = useContext(OnboardingContext);
  const [allowedIds, toggle] = useToggleSet();

  return (
    <div className="h-full flex flex-row pt-20 pb-10 pl-10 pr-4 gap-8">
      <div className="flex flex-col justify-center w-[320px] flex-shrink-0">
        <Onboarding.Heading>Grant apps internet access</Onboarding.Heading>
        <Onboarding.Text className="mt-4">
          These remaining apps can launch, but <b>can&rsquo;t access the internet,</b>
          {` `}which is a safe default. If you know any of these are safe, and need
          internet to work&mdash;you can grant them unresticted access here.
        </Onboarding.Text>
        <Onboarding.Text className="mt-3 text-sm !text-slate-400">
          Unsure? Leave it without access. You can always grant internet later from the
          parent dashboard.
        </Onboarding.Text>
        <div className="mt-8">
          <Button
            type="button"
            color="primary"
            size="large"
            className="w-full"
            onClick={() =>
              emit({
                case: `appKeysSelected`,
                bundleIds: [...allowedIds],
              })
            }
            tabIndex={-1}
          >
            {allowedIds.size > 0
              ? `Allow (${allowedIds.size}) app${allowedIds.size === 1 ? `` : `s`}`
              : `Continue`}
            <i className="fa-solid fa-arrow-right ml-3" />
          </Button>
        </div>
      </div>
      <ScrollableAppGrid>
        {apps.map((app) => (
          <AppTile
            key={app.bundleId}
            app={app}
            active={allowedIds.has(app.bundleId)}
            theme={theme}
            onToggle={toggle}
          />
        ))}
      </ScrollableAppGrid>
    </div>
  );
};

export default AllowInternetApps;
