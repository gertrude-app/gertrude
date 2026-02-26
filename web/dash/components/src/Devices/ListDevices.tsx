import { posessive } from '@shared/string';
import React from 'react';
import { Link } from 'react-router-dom';
import type { ChildComputerStatus } from '@dash/types';
import ComputerCard from '../Computers/ComputerCard';
import EmptyState from '../EmptyState';
import PageHeading from '../PageHeading';
import DeviceCard from '../Users/DeviceCard';

export type IOSDeviceItem = {
  id: string;
  childId: string;
  childName: string;
  modelName: string;
  deviceType: string;
  iosVersion: string;
  pendingSetup?: boolean;
};

export type MacDeviceItem = {
  id: string;
  name?: string;
  modelIdentifier: string;
  modelTitle: string;
  users: Array<{
    id: string;
    name: string;
    status: ChildComputerStatus;
  }>;
};

type Props = {
  computers: MacDeviceItem[];
  iosDevices: IOSDeviceItem[];
};

const ListDevices: React.FC<Props> = ({ computers, iosDevices }) => (
  <div>
    <PageHeading icon="layer-group">Devices</PageHeading>
    {computers.length === 0 && iosDevices.length === 0 && (
      <EmptyState
        className="mt-8"
        heading="No devices"
        secondaryText="Devices appear here automatically when you install and connect Gertrude on a Mac or iOS device for one of your children."
        icon="laptop"
        buttonText="See children"
        buttonIcon="users"
        action="/children"
      />
    )}
    {computers.length > 0 && (
      <section className="mt-10">
        <h2 className="text-2xl font-bold text-slate-600">Computers</h2>
        <div className="mt-3.5 grid grid-cols-1 lg+:grid-cols-2 2xl:grid-cols-3 gap-x-8 gap-y-6">
          {computers.map((device) => {
            const onlineUser = device.users.find(
              (user) => user.status.case !== `offline`,
            );
            return (
              <div key={device.id}>
                <ComputerCard
                  name={device.name}
                  id={device.id}
                  modelTitle={device.modelTitle}
                  modelIdentifier={device.modelIdentifier}
                  user={onlineUser ? { ...onlineUser, name: `` } : undefined}
                />
                <p className="text-right text-base text-slate-500 mt-3.5 mr-1">
                  Used by:{` `}
                  {device.users.map((user, i) => (
                    <React.Fragment key={user.id}>
                      {i > 0 && `, `}
                      <Link
                        to={`/children/${user.id}/mac`}
                        className="text-violet-500 hover:text-violet-700 transition-colors duration-100"
                      >
                        {user.name}
                      </Link>
                    </React.Fragment>
                  ))}
                </p>
              </div>
            );
          })}
        </div>
      </section>
    )}
    {iosDevices.length > 0 && (
      <section className={computers.length > 0 ? `mt-14` : `mt-10`}>
        <h2 className="text-2xl font-bold text-slate-600">iPhones and iPads</h2>
        <div className="mt-3.5 grid grid-cols-1 lg+:grid-cols-2 2xl:grid-cols-3 gap-x-8 gap-y-3">
          {iosDevices.map((device) => (
            <DeviceCard
              key={device.id}
              to={`/children/${device.childId}/ios-devices/${device.id}`}
              imageSrc={`/ios/${device.deviceType}.png`}
              imageAlt={device.modelName}
              title={`${posessive(device.childName)} ${device.modelName}`}
              subtitle={device.iosVersion}
              status={device.pendingSetup ? { case: `pendingSetup` } : undefined}
            />
          ))}
        </div>
      </section>
    )}
  </div>
);

export default ListDevices;
