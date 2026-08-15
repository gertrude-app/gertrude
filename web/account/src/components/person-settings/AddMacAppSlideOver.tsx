import { Button, Card, HStack, SlideOver, Text, Tooltip, VStack } from '@gertrude/ui';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import type {
  BlockedMacApp,
  InstalledMacApp,
  PublicUnrestrictedMacApp,
  UnrestrictedMacApp,
} from '#/components/pages/person-settings/MacSettingsPage.types';

type AddAppSlideOverType = `blocked` | `unrestricted`;

interface Props {
  open: boolean;
  type: AddAppSlideOverType;
  personName: string;
  installedApps: InstalledMacApp[];
  blockedApps: BlockedMacApp[];
  unrestrictedApps: UnrestrictedMacApp[];
  publicUnrestrictedApps?: PublicUnrestrictedMacApp[];
  onOpenChange: (open: boolean) => void;
  onAdd: (apps: InstalledMacApp[]) => void;
}

const blockedAppMatchesInstalledApp = (
  configuredApp: BlockedMacApp,
  installedApp: InstalledMacApp,
): boolean =>
  configuredApp.identifier === installedApp.bundleId ||
  configuredApp.identifier.toLowerCase() === installedApp.name.toLowerCase();

const unrestrictedAppMatchesInstalledApp = (
  configuredApp: Pick<UnrestrictedMacApp, `scope`>,
  installedApp: InstalledMacApp,
): boolean =>
  configuredApp.scope.type === `identifiedAppSlug`
    ? configuredApp.scope.identifiedAppSlug === installedApp.identifiedAppSlug
    : configuredApp.scope.bundleId === installedApp.bundleId;

const AddMacAppSlideOver: React.FC<Props> = ({
  open,
  type,
  personName,
  installedApps,
  blockedApps,
  unrestrictedApps,
  publicUnrestrictedApps = [],
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
  ): AddAppSlideOverType | `publicUnrestricted` | null => {
    if (
      blockedApps.some(
        (configuredApp) =>
          (type === `blocked` || configuredApp.schedule === undefined) &&
          blockedAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `blocked`;
    }

    if (
      type === `unrestricted` &&
      unrestrictedApps.some((configuredApp) =>
        unrestrictedAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `unrestricted`;
    }

    if (
      type === `unrestricted` &&
      publicUnrestrictedApps.some((configuredApp) =>
        unrestrictedAppMatchesInstalledApp(configuredApp, app),
      )
    ) {
      return `publicUnrestricted`;
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
      <VStack className="h-full">
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          <div className="grid grid-cols-2 gap-2 @md/slide:grid-cols-3">
            {installedApps.map((app) => {
              const selected = selectedInstalledAppIds.includes(app.id);
              const configurationType = getInstalledAppConfigurationType(app);
              const disabled = configurationType !== null;
              const disabledLabel =
                configurationType === type ||
                (type === `blocked` && configurationType === `unrestricted`)
                  ? `Already added`
                  : configurationType === `blocked`
                    ? `Blocked`
                    : configurationType === `unrestricted` ||
                        configurationType === `publicUnrestricted`
                      ? `Unrestricted`
                      : null;
              const disabledTooltip =
                configurationType === type
                  ? type === `blocked`
                    ? `This app is already in Blocked Apps.`
                    : `This app is already in Unrestricted Apps.`
                  : configurationType === `blocked`
                    ? `Remove its always-on block before adding it to Unrestricted Apps.`
                    : configurationType === `unrestricted`
                      ? `Remove this app from Unrestricted Apps before adding it to Blocked Apps.`
                      : configurationType === `publicUnrestricted`
                        ? `This app already has unrestricted internet through an assigned keychain.`
                        : null;
              const appButton = (
                <Card
                  as="button"
                  key={app.id}
                  type="button"
                  interactive
                  selected={selected}
                  disabled={disabled}
                  aria-pressed={selected}
                  onClick={() => toggleSelectedInstalledApp(app)}
                  className="group relative flex min-h-34 w-full flex-col items-center justify-center text-center"
                >
                  <div className="relative mb-2">
                    {app.appIconUrl ? (
                      <img src={app.appIconUrl} alt="" className="h-12 w-12" />
                    ) : (
                      <HStack
                        justify="center"
                        className="h-12 w-12 bg-stone-200 text-lg font-semibold text-stone-500"
                      >
                        {app.name.slice(0, 1).toUpperCase()}
                      </HStack>
                    )}
                    {selected && !disabled && (
                      <HStack
                        justify="center"
                        className="absolute -right-1 -top-1 h-5 w-5 rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30"
                      >
                        <CheckIcon className="h-3 w-3" strokeWidth={3} />
                      </HStack>
                    )}
                  </div>
                  <Text variant="bodyStrong">{app.name}</Text>
                  <Text variant="captionMuted" truncate className="mt-0.5 max-w-full">
                    {app.bundleId}
                  </Text>
                  {disabledLabel && (
                    <Text
                      variant="captionSubtleStrong"
                      className="mt-2 rounded-full bg-stone-200 px-2 py-0.5"
                    >
                      {disabledLabel}
                    </Text>
                  )}
                </Card>
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
        </SlideOver.Body>
        <SlideOver.Footer>
          <Text variant="bodyMuted">
            {selectedInstalledApps.length === 0
              ? `Select one or more apps`
              : `${selectedInstalledApps.length} app${
                  selectedInstalledApps.length === 1 ? `` : `s`
                } selected`}
          </Text>
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
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export default AddMacAppSlideOver;
