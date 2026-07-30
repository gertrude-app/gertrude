import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
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
  const resolvedPersonId = person?.id;
  const personName = person?.name;
  const [nameDraft, setNameDraft] = React.useState(personName ?? ``);
  const updateName = useMutation(liveClient.updatePersonName, {
    invalidating: [Key.people],
    toast: {
      loading: `Saving name…`,
      success: `Name updated`,
      error: `Failed to update name`,
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

  if (!person) {
    return null;
  }

  return (
    <PersonBasicSettingsPage
      personName={person.name}
      nameDraft={nameDraft}
      setNameDraft={setNameDraft}
      devices={person.devices}
      savingName={updateName.isPending}
      deletingPerson={deletePerson.isPending}
      onSaveName={() =>
        updateName.mutate({ personId: person.id, name: nameDraft.trim() })
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
