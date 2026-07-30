import {
  Button,
  ConfirmationDialog,
  EmptyState,
  Input,
  Stack,
  VStack,
  inflect,
} from '@gertrude/ui';
import { MonitorSmartphoneIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { Device } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DeviceListRow from '#/components/people/DeviceListRow';

interface Props {
  personName: string;
  nameDraft: string;
  setNameDraft: (name: string) => void;
  devices: Device[];
  savingName?: boolean;
  deletingPerson?: boolean;
  onSaveName: () => void;
  onDeletePerson: () => void | Promise<void>;
}

const PersonBasicSettingsPage: React.FC<Props> = ({
  personName,
  nameDraft,
  setNameDraft,
  devices,
  savingName,
  deletingPerson,
  onSaveName,
  onDeletePerson,
}) => {
  const trimmedNameDraft = nameDraft.trim();
  const nameError = trimmedNameDraft.length === 0 ? `Name is required.` : undefined;
  const canSaveName = !nameError && trimmedNameDraft !== personName;

  return (
    <div className="grid grid-cols-1 gap-y-6 gap-x-18 @5xl/main:grid-cols-[minmax(0,1fr)_20rem]">
      <VStack gap={6}>
        <CardContainer
          className="flex flex-col gap-4"
          heading="Basic details"
          subheading="Update the name used throughout Gertrude."
        >
          <Stack
            as="form"
            direction={{ default: `vertical`, '@2xl/main': `horizontal` }}
            gap={3}
            align={{ default: `stretch`, '@2xl/main': `start` }}
            onSubmit={(event) => {
              event.preventDefault();
              if (canSaveName && !savingName && !deletingPerson) {
                onSaveName();
              }
            }}
          >
            <Input
              type="text"
              label="Name"
              value={nameDraft}
              setValue={setNameDraft}
              error={nameError}
              disabled={savingName || deletingPerson}
              className="flex-grow"
            />
            <Button
              type="submit"
              variant="primary"
              disabled={!canSaveName || deletingPerson}
              loading={savingName}
              className="@2xl/main:mt-[22px]"
            >
              Save
            </Button>
          </Stack>
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
              disabled={savingName}
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
              disabled: savingName,
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
