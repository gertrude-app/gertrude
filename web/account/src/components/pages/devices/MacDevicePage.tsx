import {
  Badge,
  Button,
  EmptyState,
  HStack,
  Input,
  PageHeading,
  Select,
  type SelectOption,
  Skeleton,
  Text,
  VStack,
  inflect,
} from '@gertrude/ui';
import {
  CircleAlertIcon,
  CircleCheckIcon,
  DownloadIcon,
  RefreshCwIcon,
} from 'lucide-react';
import React from 'react';
import type { MacDeviceDetails, ReleaseChannel } from '#/components/devices/types';
import type { LoadableState } from '#/components/types';
import MacPersonStatus from '#/components/devices/MacPersonStatus';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import DeviceArtwork from '#/components/people/DeviceArtwork';

interface Props {
  state: LoadableState<MacDeviceDetails>;
  nameDraft: string;
  setNameDraft: (name: string) => void;
  releaseChannelDraft: ReleaseChannel;
  setReleaseChannelDraft: (channel: ReleaseChannel) => void;
  saving?: boolean;
  onSave: () => void;
}

const breadcrumbs = [{ text: `Devices`, href: `/devices` }];

const releaseChannelOptions: ReadonlyArray<SelectOption<ReleaseChannel>> = [
  { value: `stable`, label: `Stable` },
  { value: `beta`, label: `Beta` },
  { value: `canary`, label: `Canary` },
];

const MacDeviceLoading: React.FC = () => (
  <DashboardPage heading={<PageHeading title="Mac" breadcrumbs={breadcrumbs} />}>
    <div className="grid grid-cols-1 gap-y-6 gap-x-18 @5xl/main:grid-cols-[minmax(0,1fr)_20rem]">
      <CardContainer className="flex flex-col gap-4">
        <Skeleton className="h-5 w-24" />
        <Skeleton className="h-10 w-full" />
        <Skeleton className="h-24 w-full" />
      </CardContainer>
      <CardContainer className="flex flex-col gap-3">
        <Skeleton className="h-5 w-32" />
        <Skeleton className="h-16 w-full" />
        <Skeleton className="h-16 w-full" />
      </CardContainer>
    </div>
  </DashboardPage>
);

const MacDeviceError: React.FC<Extract<Props[`state`], { status: `error` }>> = ({
  message,
  onRetry,
}) => (
  <DashboardPage heading={<PageHeading title="Mac" breadcrumbs={breadcrumbs} />}>
    <CardContainer>
      <div role="alert">
        <EmptyState
          icon={CircleAlertIcon}
          title="Couldn't load Mac"
          description={message}
          button={{
            text: `Try again`,
            type: `button`,
            onClick: onRetry,
            icon: RefreshCwIcon,
          }}
          className="bg-white"
        />
      </div>
    </CardContainer>
  </DashboardPage>
);

const MacDevicePage: React.FC<Props> = ({
  state,
  nameDraft,
  setNameDraft,
  releaseChannelDraft,
  setReleaseChannelDraft,
  saving = false,
  onSave,
}) => {
  if (state.status === `loading`) {
    return <MacDeviceLoading />;
  }

  if (state.status === `error`) {
    return <MacDeviceError {...state} />;
  }

  const device = state.data;
  const normalizedName = nameDraft.trim();
  const hasChanges =
    normalizedName !== (device.name ?? ``) ||
    releaseChannelDraft !== device.releaseChannel;
  const targetVersion = device.targetVersions[releaseChannelDraft];
  const updateAvailable =
    device.appVersion !== undefined &&
    targetVersion !== undefined &&
    targetVersion !== device.appVersion;
  const macOSDescription = device.macOSVersion
    ? `Running macOS ${device.macOSVersion}`
    : `macOS version unavailable`;
  const subtitle = device.name
    ? `${device.modelName} · ${macOSDescription}`
    : macOSDescription;

  return (
    <DashboardPage
      heading={
        <PageHeading
          title={device.name ?? device.modelName}
          subtitle={subtitle}
          breadcrumbs={breadcrumbs}
          rightContent={
            <DeviceArtwork
              device={{ type: `mac`, modelIdentifier: device.modelIdentifier }}
              size="card"
            />
          }
        />
      }
    >
      <VStack gap={6}>
        <div className="grid grid-cols-1 gap-y-6 gap-x-18 @5xl/main:grid-cols-[minmax(0,1fr)_20rem]">
          <CardContainer
            heading="Mac details"
            subheading="Change how this Mac appears in Gertrude and which updates it receives."
            className="flex flex-col gap-4"
          >
            <form
              className="flex flex-col gap-4"
              onSubmit={(event) => {
                event.preventDefault();
                if (hasChanges && !saving) {
                  onSave();
                }
              }}
            >
              <div className="grid grid-cols-1 gap-3 @2xl/main:grid-cols-2">
                <Input
                  type="text"
                  label="Mac name"
                  value={nameDraft}
                  setValue={setNameDraft}
                  placeholder={device.modelName}
                  helperText="Leave blank to use the model name."
                  disabled={saving}
                />
                <Select
                  label="Release channel"
                  selected={releaseChannelDraft}
                  setSelected={setReleaseChannelDraft}
                  possibleValues={releaseChannelOptions}
                  disabled={saving}
                />
              </div>
              <div className="rounded-xl border border-stone-200 bg-white px-4 py-3 shadow-sm shadow-stone-300/20">
                <HStack justify="between" align="center" gap={3} wrap>
                  <Text variant="bodyStrong">
                    {device.appVersion
                      ? `Running version ${device.appVersion}`
                      : `Installed version unavailable`}
                  </Text>
                  {device.appVersion === undefined ? (
                    <Badge size="small" color="neutral">
                      Version unavailable
                    </Badge>
                  ) : updateAvailable ? (
                    <Badge size="small" color="yellow" icon={DownloadIcon}>
                      Version {targetVersion} available
                    </Badge>
                  ) : (
                    <Badge size="small" color="green" icon={CircleCheckIcon}>
                      Up to date
                    </Badge>
                  )}
                </HStack>
              </div>
              <HStack justify="end" gap={2}>
                <Button type="link" href="/devices" variant="default" disabled={saving}>
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="primary"
                  loading={saving}
                  disabled={!hasChanges}
                >
                  Save changes
                </Button>
              </HStack>
            </form>
          </CardContainer>

          <CardContainer
            heading="People using this Mac"
            subheading={`${device.people.length} ${inflect(`person`, device.people.length)} connected.`}
            className="h-fit flex flex-col gap-3"
          >
            {device.people.length > 0 ? (
              <VStack gap={2}>
                {device.people.map((person) => (
                  <MacPersonStatus key={person.id} person={person} />
                ))}
              </VStack>
            ) : (
              <Text variant="bodyMuted">No protected people are connected.</Text>
            )}
          </CardContainer>
        </div>
      </VStack>
    </DashboardPage>
  );
};

export default MacDevicePage;
