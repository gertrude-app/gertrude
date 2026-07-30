import { EmptyState, PageHeading, Skeleton, VStack } from '@gertrude/ui';
import { Outlet, createFileRoute, useLocation } from '@tanstack/react-router';
import { CircleAlertIcon, RefreshCwIcon, UserRoundXIcon } from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';
import PersonSettingsShellPage from '#/components/pages/people/PersonSettingsShellPage';
import { liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useQuery } from '#/pairql/query';

interface PersonSettingsStatusPageProps {
  title: string;
  cardClassName?: string;
  children: React.ReactNode;
}

const PersonSettingsStatusPage: React.FC<PersonSettingsStatusPageProps> = ({
  title,
  cardClassName,
  children,
}) => (
  <DashboardPage
    heading={
      <PageHeading
        title={title}
        breadcrumbs={[{ text: `Protected People`, href: `/people` }]}
      />
    }
  >
    <CardContainer className={cardClassName}>{children}</CardContainer>
  </DashboardPage>
);

const PersonSettingsRoute: React.FC = () => {
  const { personId } = Route.useParams();
  const { pathname } = useLocation();
  const query = useQuery(Key.people, () => liveClient.getPeople());
  const person = query.data?.find(
    (candidate) => candidate.id.toLowerCase() === personId.toLowerCase(),
  );

  if (query.data === undefined && query.isError) {
    return (
      <PersonSettingsStatusPage title="Person Settings">
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load person settings"
            description={
              query.error.userMessage ?? `Check your connection and try again.`
            }
            button={{
              text: `Try again`,
              type: `button`,
              onClick: () => void query.refetch(),
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </PersonSettingsStatusPage>
    );
  }

  if (query.data === undefined) {
    return (
      <PersonSettingsStatusPage
        title="Person Settings"
        cardClassName="flex flex-col gap-4"
      >
        <span role="status" className="sr-only">
          Loading person settings
        </span>
        <VStack gap={3}>
          <Skeleton className="h-5 w-36" />
          <Skeleton radius="large" className="h-24 w-full" />
          <Skeleton radius="large" className="h-40 w-full" />
        </VStack>
      </PersonSettingsStatusPage>
    );
  }

  if (!person) {
    return (
      <PersonSettingsStatusPage title="Person not found">
        <EmptyState
          icon={UserRoundXIcon}
          title="Person not found"
          description="This person may have been deleted or belong to another account."
          button={{
            text: `Back to Protected People`,
            type: `link`,
            href: `/people`,
          }}
          className="bg-white"
        />
      </PersonSettingsStatusPage>
    );
  }

  const baseHref = `/people/${personId}`;

  return (
    <PersonSettingsShellPage
      personName={person.name}
      peopleHref="/people"
      baseHref={baseHref}
      selectedHref={pathname}
    >
      <Outlet />
    </PersonSettingsShellPage>
  );
};

export const Route = createFileRoute(`/_app/people/$personId`)({
  component: PersonSettingsRoute,
});
