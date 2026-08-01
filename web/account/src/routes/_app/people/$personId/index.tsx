import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
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

  React.useEffect(() => {
    if (personName !== undefined) {
      setNameDraft(personName);
    }
  }, [resolvedPersonId, personName]);

  React.useEffect(() => {
    if (personRelationship !== undefined) {
      setRelationshipDraft(personRelationship);
    }
  }, [resolvedPersonId, personRelationship]);

  if (!person) {
    return null;
  }

  return (
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
      onDeletePerson={() =>
        deletePerson.mutateAsync({ personId: person.id }).then(
          () => undefined,
          () => undefined,
        )
      }
    />
  );
};

export const Route = createFileRoute(`/_app/people/$personId/`)({
  component: PersonBasicSettingsRoute,
});
