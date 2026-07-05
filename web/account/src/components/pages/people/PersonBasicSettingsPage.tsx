import { Button, ConfirmationDialog, EmptyState, Input, inflect } from '@gertrude/ui';
import { MonitorSmartphoneIcon, PlusIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DeviceListRow from '#/components/people/DeviceListRow';

interface Props {
  personName: string;
  nameDraft: string;
  setNameDraft: (name: string) => void;
  devices: Device[];
  deviceSettingsHref: (device: Device) => string;
  onSaveName: () => void;
  onAddDevice: () => void;
  onDeletePerson: () => void;
}

const PersonBasicSettingsPage: React.FC<Props> = ({
  personName,
  nameDraft,
  setNameDraft,
  devices,
  deviceSettingsHref,
  onSaveName,
  onAddDevice,
  onDeletePerson,
}) => {
  const trimmedNameDraft = nameDraft.trim();
  const nameError = trimmedNameDraft.length === 0 ? `Name is required.` : undefined;
  const canSaveName = !nameError && trimmedNameDraft !== personName;

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
              if (canSaveName) {
                onSaveName();
              }
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
            devices.length === 0
              ? `Add a device to get started protecting ${personName}.`
              : `${devices.length} ${inflect(`device`, devices.length)} connected to ${personName}.`
          }
          buttons={
            <Button type="button" onClick={onAddDevice} icon={PlusIcon} variant="default">
              Add Device
            </Button>
          }
        >
          {devices.length > 0 ? (
            <div className="flex flex-col gap-3">
              {devices.map((device) => (
                <DeviceListRow
                  key={device.id}
                  device={device}
                  href={deviceSettingsHref(device)}
                />
              ))}
            </div>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`Add a device to get started protecting ${personName}.`}
              button={{
                text: `Add Device`,
                type: `button`,
                onClick: onAddDevice,
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
        subheading={`Permanently delete ${personName} and all associated data.`}
        dangerZone
      >
        <ConfirmationDialog
          confirmationQuestion={`Delete ${personName}?`}
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
              onClick: onDeletePerson,
            },
          ]}
        />
      </CardContainer>
    </div>
  );
};

export default PersonBasicSettingsPage;
