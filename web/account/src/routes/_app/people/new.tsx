import { useQueryClient } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type { PersonRelationship } from '#/components/types';
import type { GetPeople } from '@shared/pairql/src/account';
import NewPersonPage from '#/components/pages/people/NewPersonPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

const NewPersonRoute: React.FC = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [relationship, setRelationship] = React.useState<PersonRelationship | null>(null);
  const [name, setName] = React.useState(``);
  const peopleQuery = useQuery(Key.people, () => liveClient.getPeople());
  const selfRelationshipUnavailable =
    peopleQuery.data?.some((person) => person.relationship === `self`) ?? false;
  React.useEffect(() => {
    if (selfRelationshipUnavailable && relationship === `self`) {
      setRelationship(null);
    }
  }, [relationship, selfRelationshipUnavailable]);

  const createPerson = useMutation(liveClient.createPerson, {
    toast: {
      loading: `Adding person…`,
      success: `Person added`,
      error: `Failed to add person`,
    },
    invalidating: [Key.people],
    onSuccess: (person) => {
      queryClient.setQueryData<GetPeople.Output>(Key.people.segments, (people) =>
        people
          ? [
              ...people,
              {
                id: person.personId,
                name: person.name,
                relationship: person.relationship,
                devices: [],
              },
            ]
          : undefined,
      );
      void navigate({
        to: `/people/$personId`,
        params: { personId: person.personId },
        replace: true,
      });
    },
  });

  return (
    <NewPersonPage
      relationship={relationship}
      setRelationship={setRelationship}
      name={name}
      setName={setName}
      creating={createPerson.isPending}
      selfRelationshipUnavailable={selfRelationshipUnavailable}
      onFinish={() => {
        if (
          relationship &&
          !(relationship === `self` && selfRelationshipUnavailable) &&
          name.trim() &&
          !createPerson.isPending
        ) {
          createPerson.mutate({ name, relationship });
        }
      }}
    />
  );
};

export const Route = createFileRoute(`/_app/people/new`)({
  component: NewPersonRoute,
});
