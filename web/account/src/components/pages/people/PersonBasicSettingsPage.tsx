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
import { MonitorSmartphoneIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Device, PersonRelationship } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DeviceListRow from '#/components/people/DeviceListRow';
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
  selfRelationshipUnavailable?: boolean;
  onSaveDetails: () => void;
  onDeletePerson: () => void | Promise<void>;
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
  selfRelationshipUnavailable = false,
  onSaveDetails,
  onDeletePerson,
}) => {
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
              if (canSaveDetails && !savingDetails && !deletingPerson) {
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
              disabled={savingDetails || deletingPerson}
              className="min-w-0"
            />
            <Select
              label="Relationship to you"
              selected={relationshipDraft}
              setSelected={setRelationshipDraft}
              possibleValues={relationshipOptions}
              disabled={savingDetails || deletingPerson}
              className="min-w-0"
            />
            <Button
              type="submit"
              variant="primary"
              disabled={!canSaveDetails || savingDetails || deletingPerson}
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
        >
          {devices.length > 0 ? (
            <VStack gap={3}>
              {devices.map((device) => (
                <DeviceListRow key={device.id} device={device} />
              ))}
            </VStack>
          ) : (
            <EmptyState
              icon={MonitorSmartphoneIcon}
              title="No Devices"
              description={`No devices are connected to ${personName} yet.`}
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
              disabled={savingDetails}
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
              disabled: savingDetails,
              loading: deletingPerson,
              autoClose: false,
              onClick: onDeletePerson,
            },
          ]}
        />
      </CardContainer>
    </div>
  );
};

export default PersonBasicSettingsPage;
