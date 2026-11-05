import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import InstallIOSAppModal from '#/components/devices/InstallIOSAppModal';
import { useConnectMac } from '#/components/devices/useConnectMac';
import { useInstallIOSApp } from '#/components/devices/useInstallIOSApp';
import PersonBasicSettingsPage from '#/components/pages/people/PersonBasicSettingsPage';
import { toPersonCardPerson } from '#/lib/people';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const PersonBasicSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const navigate = useNavigate();
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople());
  const personData = peopleQuery.data?.find(
    (candidate) => candidate.id.toLowerCase() === personId.toLowerCase(),
  );
  const person = personData ? toPersonCardPerson(personData) : undefined;
  const selfRelationshipUnavailable =
    peopleQuery.data?.some(
      (candidate) =>
        candidate.relationship === `self` &&
        candidate.id.toLowerCase() !== personId.toLowerCase(),
    ) ?? false;
  const resolvedPersonId = person?.id;
  const personName = person?.name;
  const personRelationship = person?.relationship;
  const [nameDraft, setNameDraft] = React.useState(personName ?? ``);
  const [relationshipDraft, setRelationshipDraft] = React.useState<PersonRelationship>(
    personRelationship ?? `child`,
  );
  const [allowNavigation, setAllowNavigation] = React.useState(false);
  const draftPersonId = React.useRef<string | undefined>(undefined);
  const hasUnsavedChanges =
    person !== undefined &&
    draftPersonId.current === person.id &&
    (nameDraft.trim() !== person.name || relationshipDraft !== person.relationship);
  const updateDetails = useMutation(liveClient.updatePersonBasicDetails, {
    invalidating: [Key.people],
    toast: {
      loading: `Saving details…`,
      success: `Details updated`,
      error: `Failed to update details`,
    },
  });
  const deletePerson = useMutation(liveClient.deletePerson, {
    invalidating: [
      Key.people,
      Key.accountSetup,
      Key.activitySummaries,
      Key.suspensionRequests,
    ],
    toast: {
      loading: `Deleting person…`,
      success: `Person deleted`,
      error: `Failed to delete person`,
    },
    onSuccess: () => void navigate({ to: `/people`, replace: true }),
  });
  const disconnectMac = useMutation(liveClient.disconnectMacConnection, {
    invalidating: [
      Key.people,
      Key.devices,
      Key.activity,
      Key.unlockRequests,
      Key.suspensionRequests,
      Key.securityEvents,
      Key.accountBilling,
    ],
    toast: {
      loading: `Disconnecting Mac…`,
      success: `Mac disconnected`,
      error: `Couldn't disconnect Mac`,
    },
  });
  const { connectMac, modalProps: connectMacModalProps } = useConnectMac();
  const { installIOSApp, modalProps: installModalProps } = useInstallIOSApp(person?.name);

  React.useEffect(() => {
    if (
      resolvedPersonId !== undefined &&
      personName !== undefined &&
      personRelationship !== undefined &&
      (draftPersonId.current !== resolvedPersonId || !hasUnsavedChanges)
    ) {
      draftPersonId.current = resolvedPersonId;
      setNameDraft(personName);
      setRelationshipDraft(personRelationship);
      setAllowNavigation(false);
    }
  }, [hasUnsavedChanges, personName, personRelationship, resolvedPersonId]);

  if (!person) {
    return null;
  }

  return (
    <>
      <PersonBasicSettingsPage
        personName={person.name}
        nameDraft={nameDraft}
        setNameDraft={setNameDraft}
        relationship={person.relationship}
        relationshipDraft={relationshipDraft}
        setRelationshipDraft={setRelationshipDraft}
        devices={person.devices}
        savingDetails={updateDetails.isPending}
        deletingPerson={deletePerson.isPending}
        disconnectingMac={disconnectMac.isPending}
        selfRelationshipUnavailable={selfRelationshipUnavailable}
        onSaveDetails={() =>
          updateDetails.mutate({
            personId: person.id,
            name: nameDraft,
            relationship: relationshipDraft,
          })
        }
        onDeletePerson={() => {
          setAllowNavigation(true);
          return deletePerson.mutateAsync({ personId: person.id }).then(
            () => undefined,
            () => setAllowNavigation(false),
          );
        }}
        onAddDevice={(app) =>
          app === `mac`
            ? connectMac([{ id: person.id, name: person.name }])
            : installIOSApp(app)
        }
        onDisconnectMac={(connectionId) =>
          disconnectMac.mutateAsync({ connectionId }).then(
            () => true,
            () => false,
          )
        }
      />
      <ConnectMacModal {...connectMacModalProps} />
      <InstallIOSAppModal {...installModalProps} />
      <UnsavedChangesGuard
        hasUnsavedChanges={hasUnsavedChanges && !allowNavigation}
        description="Your basic settings haven't been saved."
      />
    </>
  );
};

export const Route = createFileRoute(`/_app/people/$personId/`)({
  component: PersonBasicSettingsRoute,
});
