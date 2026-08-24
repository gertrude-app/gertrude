import { Card, EmptyState, PageHeading, Skeleton, VStack, inflect } from '@gertrude/ui';
import { CircleAlertIcon, MonitorSmartphoneIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { DevicesPageData } from '#/components/devices/types';
import type { LoadableState } from '#/components/types';
import MacDeviceCard from '#/components/devices/MacDeviceCard';
import MobileDeviceCard from '#/components/devices/MobileDeviceCard';
import CardContainer from '#/components/layout/CardContainer';
import DashboardPage from '#/components/layout/DashboardPage';

interface Props {
  state: LoadableState<DevicesPageData>;
  peopleHref: string;
}

const DeviceCardSkeleton: React.FC = () => (
  <Card preset="big" padding={0} className="flex h-full flex-col">
    <Card.Body padding={2.5} className="shrink-0">
      <div className="flex items-center gap-2.5">
        <Skeleton radius="large" className="h-14 w-18 shrink-0" />
        <VStack gap={1.5} className="flex-grow">
          <Skeleton className="h-4 w-2/3" />
          <Skeleton className="h-3.5 w-1/2" />
        </VStack>
      </div>
    </Card.Body>
    <Card.Footer className="flex grow flex-col px-2.5 py-2.5">
      <VStack gap={2}>
        <Skeleton className="h-3 w-20" />
        <Skeleton className="h-5 w-2/3" />
      </VStack>
    </Card.Footer>
  </Card>
);

const DevicesLoading: React.FC = () => (
  <>
    <span role="status" className="sr-only">
      Loading devices
    </span>
    <CardContainer
      heading="Macs"
      subheading="Loading the Macs connected to your account."
      className="flex flex-col gap-4"
    >
      <div className="grid grid-cols-1 items-start gap-4 @4xl/main:grid-cols-2">
        <DeviceCardSkeleton />
        <DeviceCardSkeleton />
      </div>
    </CardContainer>
    <CardContainer
      heading="iPhones & iPads"
      subheading="Loading the mobile devices connected to your account."
      className="flex flex-col gap-4"
    >
      <div className="grid grid-cols-1 items-start gap-4 @4xl/main:grid-cols-2">
        <DeviceCardSkeleton />
      </div>
    </CardContainer>
  </>
);

const DevicesPage: React.FC<Props> = ({ state, peopleHref }) => {
  let content: React.ReactNode;

  if (state.status === `loading`) {
    content = <DevicesLoading />;
  } else if (state.status === `error`) {
    content = (
      <CardContainer>
        <div role="alert">
          <EmptyState
            icon={CircleAlertIcon}
            title="Couldn't load devices"
            description={state.message}
            button={{
              text: `Try again`,
              type: `button`,
              onClick: state.onRetry,
              icon: RefreshCwIcon,
            }}
            className="bg-white"
          />
        </div>
      </CardContainer>
    );
  } else if (state.data.macs.length === 0 && state.data.mobileDevices.length === 0) {
    content = (
      <CardContainer>
        <EmptyState
          icon={MonitorSmartphoneIcon}
          title="No devices connected"
          description="Devices appear here after a Gertrude app is connected for a protected person."
          button={{
            text: `View protected people`,
            type: `link`,
            href: peopleHref,
          }}
          className="bg-white"
        />
      </CardContainer>
    );
  } else {
    content = (
      <>
        {state.data.macs.length > 0 && (
          <CardContainer
            heading="Macs"
            subheading={`${state.data.macs.length} ${inflect(`Mac`, state.data.macs.length)} connected to your account.`}
            className="flex flex-col gap-4"
          >
            <div className="grid grid-cols-1 items-start gap-4 @4xl/main:grid-cols-2">
              {state.data.macs.map((device) => (
                <MacDeviceCard key={device.id} device={device} />
              ))}
            </div>
          </CardContainer>
        )}
        {state.data.mobileDevices.length > 0 && (
          <CardContainer
            heading="iPhones & iPads"
            subheading={`${state.data.mobileDevices.length} ${inflect(`device`, state.data.mobileDevices.length)} connected to your account.`}
            className="flex flex-col gap-4"
          >
            <div className="grid grid-cols-1 items-start gap-4 @4xl/main:grid-cols-2">
              {state.data.mobileDevices.map((device) => (
                <MobileDeviceCard key={device.id} device={device} />
              ))}
            </div>
          </CardContainer>
        )}
      </>
    );
  }

  return (
    <DashboardPage
      heading={
        <PageHeading
          title="Devices"
          subtitle="The Macs, iPhones, and iPads connected to your Gertrude account."
        />
      }
    >
      <VStack gap={6}>{content}</VStack>
    </DashboardPage>
  );
};

export default DevicesPage;
