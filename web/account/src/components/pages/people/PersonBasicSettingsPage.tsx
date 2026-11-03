import {
  Button,
  ConfirmationDialog,
  EmptyState,
  Input,
  Select,
  type SelectOption,
  VStack,
  inflect,
} from '@gertrude/ui';
import { LaptopIcon, MonitorSmartphoneIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Device, PersonRelationship } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DeviceListRow from '#/components/people/DeviceListRow';
import { deviceTitle } from '#/components/utils';
import { selfRelationshipUnavailableMessage } from '#/lib/people';

interface Props {
  personName: string;
  nameDraft: string;
  setNameDraft: (name: string) => void;
  relationship: PersonRelationship;
  relationshipDraft: PersonRelationship;
  setRelationshipDraft: (relationship: PersonRelationship) => void;
  devices: Device[];
  savingDetails?: boolean;
  deletingPerson?: boolean;
  disconnectingMac?: boolean;
  selfRelationshipUnavailable?: boolean;
  onSaveDetails: () => void;
  onDeletePerson: () => void | Promise<void>;
  onConnectMac: () => void;
  onDisconnectMac: (connectionId: string) => Promise<boolean>;
}

const PersonBasicSettingsPage: React.FC<Props> = ({
  personName,
  nameDraft,
  setNameDraft,
  relationship,
  relationshipDraft,
  setRelationshipDraft,
  devices,
  savingDetails,
  deletingPerson,
  disconnectingMac,
  selfRelationshipUnavailable = false,
  onSaveDetails,
  onDeletePerson,
  onConnectMac,
  onDisconnectMac,
}) => {
  const [disconnectDevice, setDisconnectDevice] = React.useState<Extract<
    Device,
    { type: `mac` }
  > | null>(null);
  const busy = savingDetails || deletingPerson || disconnectingMac;
  const trimmedNameDraft = nameDraft.trim();
  const nameError = trimmedNameDraft.length === 0 ? `Name is required.` : undefined;
  const detailsChanged =
    trimmedNameDraft !== personName || relationshipDraft !== relationship;
  const relationshipAvailable =
    relationshipDraft !== `self` || !selfRelationshipUnavailable;
  const canSaveDetails = !nameError && relationshipAvailable && detailsChanged;
  const relationshipOptions: Array<SelectOption<PersonRelationship>> = [
    { value: `child`, label: `My child` },
    { value: `peer`, label: `A spouse, friend, or peer` },
    {
      value: `self`,
      label: `Myself`,
      disabled: selfRelationshipUnavailable,
      disabledTooltip: selfRelationshipUnavailable
        ? selfRelationshipUnavailableMessage
        : undefined,
    },
  ];

  return (
    <div className="grid grid-cols-1 gap-y-6 gap-x-18 @5xl/main:grid-cols-[minmax(0,1fr)_20rem]">
      <VStack gap={6}>
        <CardContainer
          className="flex flex-col gap-4"
          heading="Basic details"
          subheading="Update this person's name and relationship to you."
        >
          <form
            className="grid grid-cols-1 gap-3 @lg/main:grid-cols-2 @2xl/main:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto] @2xl/main:items-start"
            onSubmit={(event) => {
              event.preventDefault();
              if (canSaveDetails && !busy) {
                onSaveDetails();
              }
            }}
          >
            <Input
              type="text"
              label="Name"
              value={nameDraft}
              setValue={setNameDraft}
              error={nameError}
              disabled={busy}
              className="min-w-0"
            />
            <Select
              label="Relationship to you"
              selected={relationshipDraft}
              setSelected={setRelationshipDraft}
              possibleValues={relationshipOptions}
              disabled={busy}
              className="min-w-0"
            />
            <Button
              type="submit"
              variant="primary"
              disabled={!canSaveDetails || busy}
              loading={savingDetails}
              className="@lg/main:col-span-2 @2xl/main:col-span-1 @2xl/main:mt-[22px]"
            >
              Save Changes
            </Button>
          </form>
        </CardContainer>

        <CardContainer
          className="flex flex-col gap-4"
          heading="Devices"
          subheading={
            devices.length > 0
              ? `${devices.length} ${inflect(`device`, devices.length)} connected to ${personName}.`
              : undefined
          }
          buttons={
            devices.length > 0 ? (
              <Button
                type="button"
                variant="default"
                icon={LaptopIcon}
                disabled={busy}
                onClick={onConnectMac}
              >
                Connect a Mac
              </Button>
            ) : undefined
          }
        >
          {devices.length > 0 ? (
            <VStack gap={3}>
              {devices.map((device) => (
                <DeviceListRow
                  key={device.id}
                  device={device}
                  action={
                    device.type === `mac` ? (
                      <Button
                        type="button"
                        variant="ghost"
                        icon={TrashIcon}
                        size="small"
                        disabled={busy}
                        onClick={() => setDisconnectDevice(device)}
                      >
                        Disconnect
                      </Button>
                    ) : undefined
                  }
                />
              ))}
            </VStack>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`No devices are connected to ${personName} yet.`}
              button={{
                type: `button`,
                text: `Connect a Mac`,
                icon: LaptopIcon,
                variant: `primary`,
                disabled: busy,
                onClick: onConnectMac,
              }}
            />
          )}
        </CardContainer>
      </VStack>

      <CardContainer
        className="h-fit flex flex-col gap-3"
        heading="Danger zone"
        subheading={`Permanently delete ${personName} and all associated data.`}
        dangerZone
      >
        <ConfirmationDialog
          confirmationQuestion={`Delete ${personName}?`}
          description="This will remove the person, devices, activity, requests, and settings. This cannot be undone."
          trigger={
            <Button
              type="button"
              onClick={() => {}}
              icon={TrashIcon}
              variant="destructive"
              disabled={busy}
              loading={deletingPerson}
              className="w-full"
            >
              Delete {personName}
            </Button>
          }
          actions={[
            { text: `Cancel` },
            {
              text: `Delete ${personName}`,
              icon: TrashIcon,
              variant: `destructive`,
              disabled: busy,
              loading: deletingPerson,
              autoClose: false,
              onClick: onDeletePerson,
            },
          ]}
        />
      </CardContainer>
      <ConfirmationDialog
        open={disconnectDevice !== null}
        onOpenChange={(open) => {
          if (!open && !disconnectingMac) {
            setDisconnectDevice(null);
          }
        }}
        confirmationQuestion="Disconnect this Mac?"
        description={
          disconnectDevice && (
            <VStack gap={3}>
              <p>
                Disconnect {personName} from {deviceTitle(disconnectDevice)} (Mac user:
                {` `}
                {disconnectDevice.username})? Activity and requests from this connection
                will be deleted.
              </p>
              <p>
                {personName}, their settings, and other device connections will be kept.
                This does not uninstall Gertrude or turn off its Mac filter. Reconnecting
                requires a new connection code.
              </p>
            </VStack>
          )
        }
        actions={[
          { text: `Cancel`, disabled: disconnectingMac },
          {
            text: `Disconnect Mac`,
            icon: TrashIcon,
            variant: `destructive`,
            loading: disconnectingMac,
            autoClose: false,
            onClick: async () => {
              if (disconnectDevice && (await onDisconnectMac(disconnectDevice.id))) {
                setDisconnectDevice(null);
              }
            },
          },
        ]}
      />
    </div>
  );
};

export default PersonBasicSettingsPage;
