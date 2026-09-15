import { useQueryClient } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { ConnectMacState } from '#/components/devices/ConnectMacModal';
import type { PersonRelationship } from '#/components/types';
import UnsavedChangesGuard from '#/components/UnsavedChangesGuard';
import ConnectMacModal from '#/components/devices/ConnectMacModal';
import PersonBasicSettingsPage from '#/components/pages/people/PersonBasicSettingsPage';
import { toPersonCardPerson } from '#/lib/people';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const PersonBasicSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
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
  const [connectMacOpen, setConnectMacOpen] = React.useState(false);
  const [macTrialStarted, setMacTrialStarted] = React.useState(false);
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
    invalidating: [Key.people, Key.activitySummaries, Key.suspensionRequests],
    toast: {
      loading: `Deleting person…`,
      success: `Person deleted`,
      error: `Failed to delete person`,
    },
    onSuccess: () => void navigate({ to: `/people`, replace: true }),
  });
  const createMacConnectionCode = useMutation(liveClient.createMacConnectionCode);
  const startMacTrial = useMutation(liveClient.startAccountFullTrial, {
    invalidating: [Key.accountBilling],
    toast: {
      loading: `Starting trial…`,
      success: `Full trial started`,
      error: `Couldn't start the trial`,
    },
    onSuccess: () => setMacTrialStarted(true),
  });

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

  const connectionOutput = createMacConnectionCode.data;
  const connectMacState: ConnectMacState = createMacConnectionCode.isPending
    ? { case: `instructions`, requesting: true }
    : createMacConnectionCode.isError
      ? {
          case: `error`,
          message:
            createMacConnectionCode.error.userMessage ??
            `Couldn't create a connection code. Check your connection and try again.`,
        }
      : connectionOutput?.gate === `trialRequired` && !macTrialStarted
        ? { case: `trialRequired`, startingTrial: startMacTrial.isPending }
        : connectionOutput?.gate === `planUpgradeRequired`
          ? { case: `planUpgradeRequired` }
          : connectionOutput?.gate === `subscriptionFixRequired`
            ? { case: `subscriptionFixRequired` }
            : connectionOutput
              ? { case: `ready`, code: connectionOutput.code }
              : { case: `instructions` };

  const handleConnectMacOpenChange = (open: boolean): void => {
    setConnectMacOpen(open);
    if (!open) {
      createMacConnectionCode.reset();
      startMacTrial.reset();
      setMacTrialStarted(false);
      void peopleQuery.refetch();
      void queryClient.invalidateQueries({ queryKey: Key.devices.segments });
    }
  };

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
        onConnectMac={() => {
          createMacConnectionCode.reset();
          startMacTrial.reset();
          setMacTrialStarted(false);
          setConnectMacOpen(true);
        }}
      />
      <ConnectMacModal
        open={connectMacOpen}
        onOpenChange={handleConnectMacOpenChange}
        personName={person.name}
        state={connectMacState}
        onRequestCode={() => createMacConnectionCode.mutate({ personId: person.id })}
        onStartTrial={() => startMacTrial.mutate(undefined)}
      />
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
