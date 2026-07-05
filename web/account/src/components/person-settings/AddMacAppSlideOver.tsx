import { Button, SlideOver, Tooltip } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import type { ConfiguredMacApp, InstalledMacApp } from '#/components/types';

type AddAppSlideOverType = `blocked` | `unrestricted`;

type ConfiguredAppReference = {
  nameOrBundleId: string;
};

interface Props {
  open: boolean;
  type: AddAppSlideOverType;
  personName: string;
  installedApps: InstalledMacApp[];
  blockedApps: ConfiguredMacApp[];
  unrestrictedApps: ConfiguredAppReference[];
  onOpenChange: (open: boolean) => void;
  onAdd: (apps: InstalledMacApp[]) => void;
}

const configuredAppMatchesInstalledApp = (
  configuredApp: ConfiguredAppReference,
  installedApp: InstalledMacApp,
): boolean =>
  configuredApp.nameOrBundleId === installedApp.name ||
  configuredApp.nameOrBundleId === installedApp.bundleId;

const AddMacAppSlideOver: React.FC<Props> = ({
  open,
  type,
  personName,
  installedApps,
  blockedApps,
  unrestrictedApps,
  onOpenChange,
  onAdd,
}) => {
  const [selectedInstalledAppIds, setSelectedInstalledAppIds] = React.useState<string[]>(
    [],
  );
  const selectedInstalledApps = installedApps.filter((app) =>
    selectedInstalledAppIds.includes(app.id),
  );
  const getInstalledAppConfigurationType = (
    app: InstalledMacApp,
  ): AddAppSlideOverType | null => {
    if (
      blockedApps.some((configuredApp) =>
        configuredAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `blocked`;
    }

    if (
      unrestrictedApps.some((configuredApp) =>
        configuredAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `unrestricted`;
    }

    return null;
  };
  const reset = (): void => {
    setSelectedInstalledAppIds([]);
  };
  const handleOpenChange = (nextOpen: boolean): void => {
    if (!nextOpen) {
      reset();
    }

    onOpenChange(nextOpen);
  };
  const toggleSelectedInstalledApp = (app: InstalledMacApp): void => {
    if (getInstalledAppConfigurationType(app)) {
      return;
    }

    setSelectedInstalledAppIds((currentIds) =>
      currentIds.includes(app.id)
        ? currentIds.filter((id) => id !== app.id)
        : [...currentIds, app.id],
    );
  };
  const addSelectedInstalledApps = (): void => {
    if (selectedInstalledApps.length === 0) {
      return;
    }

    onAdd(selectedInstalledApps);
    handleOpenChange(false);
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={handleOpenChange}
      ariaLabel={type === `unrestricted` ? `Add unrestricted apps` : `Add blocked apps`}
      heading={type === `unrestricted` ? `Add unrestricted apps` : `Add blocked apps`}
      subheading={`Choose one or more apps installed on ${personName}'s Mac.`}
      size="large"
    >
      <div className="flex h-full flex-col">
        <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4 @lg/slide:px-6">
          <div className="grid grid-cols-2 gap-2 @md/slide:grid-cols-3">
            {installedApps.map((app) => {
              const selected = selectedInstalledAppIds.includes(app.id);
              const configurationType = getInstalledAppConfigurationType(app);
              const disabled = configurationType !== null;
              const disabledLabel =
                configurationType === type
                  ? `Already added`
                  : configurationType === `blocked`
                    ? `Blocked`
                    : configurationType === `unrestricted`
                      ? `Unrestricted`
                      : null;
              const disabledTooltip =
                configurationType === type
                  ? type === `blocked`
                    ? `This app is already in Blocked Apps.`
                    : `This app is already in Unrestricted Apps.`
                  : configurationType === `blocked`
                    ? `Remove this app from Blocked Apps before adding it to Unrestricted Apps.`
                    : configurationType === `unrestricted`
                      ? `Remove this app from Unrestricted Apps before adding it to Blocked Apps.`
                      : null;
              const appButton = (
                <button
                  key={app.id}
                  type="button"
                  disabled={disabled}
                  aria-pressed={selected}
                  onClick={() => toggleSelectedInstalledApp(app)}
                  className={cx(
                    `group relative flex min-h-34 w-full flex-col items-center justify-center rounded-xl border p-3 text-center shadow transition-[background-color,border-color,box-shadow,opacity] duration-150`,
                    disabled
                      ? `cursor-not-allowed border-stone-200 bg-stone-100/70 opacity-60 shadow-transparent`
                      : selected
                        ? `cursor-pointer border-violet-300 bg-violet-50 shadow-violet-300/30 hover:border-violet-400 hover:shadow-violet-300/50`
                        : `cursor-pointer border-stone-200 bg-white shadow-stone-300/30 hover:border-stone-400/70 hover:shadow-stone-300/70`,
                  )}
                >
                  <div className="relative mb-2">
                    <img
                      src={app.appIconUrl}
                      alt=""
                      className="w-10 h-10 absolute blur-xs opacity-50"
                    />
                    <img
                      src={app.appIconUrl}
                      alt=""
                      className="w-10 h-10 shadow rounded-[11px] relative"
                    />
                    {selected && !disabled && (
                      <span className="absolute -right-1 -top-1 flex h-5 w-5 items-center justify-center rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30">
                        <CheckIcon className="h-3 w-3" strokeWidth={3} />
                      </span>
                    )}
                  </div>
                  <span className="text-sm font-medium text-stone-800">{app.name}</span>
                  <span className="mt-0.5 max-w-full truncate text-xs text-stone-500">
                    {app.bundleId}
                  </span>
                  {disabledLabel && (
                    <span className="mt-2 rounded-full bg-stone-200 px-2 py-0.5 text-xs font-medium text-stone-600">
                      {disabledLabel}
                    </span>
                  )}
                </button>
              );

              return disabledTooltip ? (
                <Tooltip key={app.id} content={disabledTooltip} side="top">
                  <span className="block h-full">{appButton}</span>
                </Tooltip>
              ) : (
                appButton
              );
            })}
          </div>
        </div>
        <div className="flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-3 py-3 @lg/slide:px-6 @lg/slide:py-4">
          <span className="text-sm text-stone-600">
            {selectedInstalledApps.length === 0
              ? `Select one or more apps`
              : `${selectedInstalledApps.length} app${
                  selectedInstalledApps.length === 1 ? `` : `s`
                } selected`}
          </span>
          <Button
            type="button"
            variant="primary"
            disabled={selectedInstalledApps.length === 0}
            onClick={addSelectedInstalledApps}
          >
            {selectedInstalledApps.length === 0
              ? type === `unrestricted`
                ? `Add to Unrestricted Apps`
                : `Add to Blocked Apps`
              : type === `unrestricted`
                ? `Add ${selectedInstalledApps.length} App${
                    selectedInstalledApps.length === 1 ? `` : `s`
                  } to Unrestricted Apps`
                : `Add ${selectedInstalledApps.length} App${
                    selectedInstalledApps.length === 1 ? `` : `s`
                  } to Blocked Apps`}
          </Button>
        </div>
      </div>
    </SlideOver>
  );
};

export default AddMacAppSlideOver;
