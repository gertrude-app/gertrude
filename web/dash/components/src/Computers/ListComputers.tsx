import React from 'react';
import type { Device } from '@dash/types';
import PageHeading from '../PageHeading';
import EmptyState from '../EmptyState';
import ComputerCard from './ComputerCard';

interface Props {
  devices: Array<
    Pick<Device, 'name' | 'id' | 'modelIdentifier' | 'modelTitle' | 'users'>
  >;
}

const ListComputers: React.FC<Props> = ({ devices }) => (
  <div>
    <PageHeading icon={`desktop`}>Computers</PageHeading>
    {devices.length === 0 && (
      <EmptyState
        className="mt-8"
        heading="No computers"
        secondaryText="Computers are created automatically when you install and connect the Gertrude Mac app for one of your children."
        icon="desktop"
        buttonText="See children"
        buttonIcon="users"
        action="/children"
      />
    )}
    <div className="mt-8 grid grid-cols-1 lg+:grid-cols-2 2xl:grid-cols-3 gap-8">
      {devices.map((device) => {
        const onlineUser = device.users.find((user) => user.status.case !== `offline`);
        return (
          <ComputerCard
            key={device.id}
            name={device.name}
            id={device.id}
            modelTitle={device.modelTitle}
            modelIdentifier={device.modelIdentifier}
            onlineUser={onlineUser?.name}
          />
        );
      })}
    </div>
  </div>
);

export default ListComputers;
