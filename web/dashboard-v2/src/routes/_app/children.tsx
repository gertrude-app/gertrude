import React from 'react';
import { PlusIcon } from 'lucide-react';
import { createFileRoute } from '@tanstack/react-router';
import { PageHeading } from '@gertrude/ui';
import DashboardPage from '#/components/DashboardPage';
import { mockChildren } from '#/lib/mock-data';
import ChildCard from '#/components/ChildCard';
import CardContainer from '#/components/CardContainer';

const ChildrenPage: React.FC = () => (
  <DashboardPage
    heading={
      <PageHeading
        title="Children"
        buttons={[
          {
            text: 'Add Child',
            onClick: () => {},
            variant: 'primary',
            icon: PlusIcon,
          },
        ]}
      />
    }
  >
    <CardContainer className="grid grid-cols-2 gap-6">
      {mockChildren.map((c) => (
        <ChildCard child={c} />
      ))}
    </CardContainer>
  </DashboardPage>
);

export const Route = createFileRoute('/_app/children')({
  component: ChildrenPage,
});
