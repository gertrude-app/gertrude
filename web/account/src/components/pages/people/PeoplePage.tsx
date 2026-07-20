import { EmptyState, PageHeading } from '@gertrude/ui';
import { ScanEyeIcon, UsersIcon } from 'lucide-react';
import React from 'react';
import type { PersonCardPerson } from '#/components/types';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import PersonCard from '#/components/people/PersonCard';

interface Props {
  people: PersonCardPerson[];
  monitorHref: string;
  monitorHrefForPerson: (personId: string) => string;
}

const PeoplePage: React.FC<Props> = ({ people, monitorHref, monitorHrefForPerson }) => (
  <DashboardPage
    heading={
      <PageHeading
        title="Protected People"
        buttons={[
          {
            text: `Monitor`,
            href: monitorHref,
            variant: `primary`,
            icon: ScanEyeIcon,
          },
        ]}
      />
    }
  >
    <CardContainer className="flex flex-col gap-4 @xl/main:gap-6">
      {people.length === 0 ? (
        <EmptyState
          icon={UsersIcon}
          title="No protected people"
          description="No one has been added to this account yet."
          className="bg-white"
        />
      ) : (
        people.map((person) => (
          <PersonCard
            key={person.id}
            person={person}
            monitorHref={monitorHrefForPerson(person.id)}
          />
        ))
      )}
    </CardContainer>
  </DashboardPage>
);

export default PeoplePage;
