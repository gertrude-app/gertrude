import {
  Badge,
  Button,
  ConfirmationDialog,
  EmptyState,
  Input,
  inflect,
} from '@gertrude/ui';
import { Link, createFileRoute, useNavigate } from '@tanstack/react-router';
import { MonitorSmartphoneIcon, PlusIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/CardContainer';
import { deviceImageUrl } from '#/lib/device-images';
import { type Device, getPerson, useMockData } from '#/lib/mock';

const deviceTitle = (device: Device): string =>
  device.type === `mac` ? (device.name ?? device.modelName) : device.modelName;

const deviceSubtitle = (device: Device): string => {
  if (device.type === `mac`) {
    return `${device.name ? `${device.modelName} • ` : ``}macOS ${device.macOSVersion}`;
  }

  return `${device.type === `iphone` ? `iOS` : `iPadOS`} ${device.iOSVersion}`;
};

const deviceSettingsHref = (device: Device): string =>
  device.type === `mac`
    ? `/people/${device.personId}/mac-settings`
    : `/people/${device.personId}/ios-settings`;

const BasicSettingsPage: React.FC = () => {
  const { personId } = Route.useParams();
  const navigate = useNavigate();
  const { db, dispatch } = useMockData();
  const person = getPerson(db, personId);
  const [nameDraft, setNameDraft] = React.useState(person?.name ?? ``);

  React.useEffect(() => {
    setNameDraft(person?.name ?? ``);
  }, [person?.name, personId]);

  if (!person) {
    return (
      <CardContainer className="flex flex-col items-center gap-3">
        <span className="text-sm text-stone-500">
          This protected person no longer exists.
        </span>
        <Button type="link" href="/people">
          Back to Protected People
        </Button>
      </CardContainer>
    );
  }

  const trimmedNameDraft = nameDraft.trim();
  const nameError = trimmedNameDraft.length === 0 ? `Name is required.` : undefined;
  const canSaveName = !nameError && trimmedNameDraft !== person.name;
  const saveName = (): void => {
    if (!canSaveName) {
      return;
    }

    dispatch({ type: `person.updateName`, id: personId, name: trimmedNameDraft });
  };
  const deletePerson = (): void => {
    dispatch({ type: `person.delete`, id: personId });
    void navigate({ to: `/people` });
  };

  return (
    <div className="grid grid-cols-1 gap-y-6 gap-x-18 @5xl/main:grid-cols-[minmax(0,1fr)_20rem]">
      <div className="flex flex-col gap-6">
        <CardContainer
          className="flex flex-col gap-4"
          heading="Basic details"
          subheading="Update the name used throughout Gertrude."
        >
          <form
            className="flex flex-col gap-3 @2xl/main:flex-row @2xl/main:items-start"
            onSubmit={(event) => {
              event.preventDefault();
              saveName();
            }}
          >
            <Input
              type="text"
              label="Child's name"
              value={nameDraft}
              setValue={setNameDraft}
              error={nameError}
              className="flex-grow"
            />
            <Button
              type="submit"
              variant="primary"
              disabled={!canSaveName}
              className="@2xl/main:mt-[22px]"
            >
              Save
            </Button>
          </form>
        </CardContainer>

        <CardContainer
          className="flex flex-col gap-4"
          heading="Devices"
          subheading={
            person.devices.length === 0
              ? `Add a device to get started protecting ${person.name}.`
              : `${person.devices.length} ${inflect(`device`, person.devices.length)} connected to ${person.name}.`
          }
          buttons={
            <Button type="button" onClick={() => {}} icon={PlusIcon} variant="default">
              Add Device
            </Button>
          }
        >
          {person.devices.length > 0 ? (
            <div className="flex flex-col gap-3">
              {person.devices.map((device) => (
                <DeviceListRow key={device.id} device={device} />
              ))}
            </div>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`Add a device to get started protecting ${person.name}.`}
              button={{
                text: `Add Device`,
                type: `button`,
                onClick: () => {},
                icon: PlusIcon,
                variant: `primary`,
              }}
            />
          )}
        </CardContainer>
      </div>

      <CardContainer
        className="h-fit flex flex-col gap-3"
        heading="Danger zone"
        subheading={`Permanently delete ${person.name} and all associated data.`}
        dangerZone
      >
        <ConfirmationDialog
          confirmationQuestion={`Delete ${person.name}?`}
          description="This will remove the child, devices, activity, requests, and settings. This cannot be undone."
          trigger={
            <Button
              type="button"
              onClick={() => {}}
              icon={TrashIcon}
              variant="destructive"
              className="w-full"
            >
              Delete child
            </Button>
          }
          actions={[
            { text: `Cancel` },
            {
              text: `Delete child`,
              icon: TrashIcon,
              variant: `destructive`,
              onClick: deletePerson,
            },
          ]}
        />
      </CardContainer>
    </div>
  );
};

interface DeviceListRowProps {
  device: Device;
}

const DeviceListRow: React.FC<DeviceListRowProps> = ({ device }) => (
  <Link
    to={deviceSettingsHref(device)}
    className="flex items-center justify-between gap-3 rounded-xl border border-stone-200 bg-white p-3 pr-6 shadow shadow-stone-300/30 transition-[border-color,box-shadow] duration-100 hover:border-stone-300 hover:shadow-stone-300/70 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-300/80"
  >
    <div className="flex min-w-0 items-center gap-3">
      <div className="flex h-10 w-12 shrink-0 items-center justify-center text-stone-700">
        <img
          src={deviceImageUrl(device.type, device.modelIdentifier)}
          alt=""
          className="h-9 w-11 object-contain drop-shadow-sm"
        />
      </div>
      <div className="min-w-0 flex flex-col">
        <span className="truncate font-medium text-stone-900">{deviceTitle(device)}</span>
        <span className="truncate text-sm text-stone-500">{deviceSubtitle(device)}</span>
      </div>
    </div>
    <Badge
      size="small"
      color={device.type === `mac` && device.online ? `green` : `neutral`}
    >
      {device.type === `mac`
        ? device.online
          ? `Online`
          : `Offline`
        : device.type === `iphone`
          ? `iPhone`
          : `iPad`}
    </Badge>
  </Link>
);

export const Route = createFileRoute(`/_app/people/$personId/`)({
  component: BasicSettingsPage,
});
