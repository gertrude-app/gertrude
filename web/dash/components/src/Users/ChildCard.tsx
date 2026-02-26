import { Button } from '@shared/components';
import { inflect } from '@shared/string';
import React from 'react';
import type { ChildComputer, ChildIOSDevice } from '@dash/types';
import DeviceCard from './DeviceCard';

type Props = {
  id: string;
  name: string;
  computers: ChildComputer[];
  iosDevices: ChildIOSDevice[];
  addDevice(): unknown;
};

const ChildCard: React.FC<Props> = ({ id, name, computers, iosDevices, addDevice }) => (
  <div
    className="rounded-3xl border-[0.5px] border-slate-200 flex flex-col justify-between shadow-lg shadow-slate-300/50 bg-white sm:min-w-[400px]"
    data-test="user-card"
  >
    <div className="p-4 xs:p-6">
      <h2 className="text-3xl font-extrabold text-slate-700 mb-4">{name}</h2>
      {computers.length || iosDevices.length ? (
        <>
          <div className="text-lg mt-4 -mb-4">
            <p className="text-slate-500">
              <span className="text-xl font-bold text-slate-600">
                {computers.length + iosDevices.length}
              </span>
              {` `}
              {inflect(
                iosDevices.length > 0 ? `device` : `computer`,
                computers.length + iosDevices.length,
              )}
              :
            </p>
          </div>
          <div className="flex flex-col mt-3 gap-3 pt-3">
            {computers.map((computer) => (
              <DeviceCard
                key={computer.id}
                to={`/devices/${computer.computerId}`}
                imageSrc={`/macs/${computer.modelIdentifier}.png`}
                imageAlt={computer.modelTitle}
                title={computer.customName || computer.modelTitle}
                subtitle={computer.customName ? computer.modelTitle : undefined}
                status={{ case: `computerStatus`, status: computer.status }}
              />
            ))}
            {iosDevices.map((device) => (
              <DeviceCard
                key={device.id}
                to={
                  device.pendingClaimCode === undefined
                    ? `/children/${id}/ios-devices/${device.id}`
                    : `/supervise-device/${device.pendingClaimCode}/download-helper`
                }
                imageSrc={`/ios/${device.deviceType}.png`}
                imageAlt={device.modelName}
                title={device.modelName}
                subtitle={device.iosVersion}
                status={
                  device.pendingClaimCode !== undefined
                    ? { case: `pendingSetup` }
                    : undefined
                }
              />
            ))}
          </div>
        </>
      ) : (
        <div className="bg-slate-50 p-6 flex flex-col justify-center items-center rounded-xl">
          <h2 className="text-xl font-medium text-slate-500 mb-4 italic">
            <i className="fa-solid fa-exclamation-triangle text-lg mr-2" />
            Setup incomplete
          </h2>
          <Button type="link" color="secondary" to={id} size="large">
            Finish setup <i className="fa-solid fa-arrow-right ml-2" />
          </Button>
        </div>
      )}
      <div
        className={`flex ${
          computers.length === 0 && iosDevices.length === 0
            ? `justify-center`
            : `justify-end`
        } mt-3 mr-2`}
      >
        {computers.length > 0 && (
          <button
            className="w-8 h-8 rounded-full bg-violet-50 flex justify-center items-center text-violet-400 text-lg hover:bg-violet-100 transition-colors duration-100 hover:text-violet-500"
            onClick={addDevice}
          >
            <i className="fa-solid fa-plus" />
          </button>
        )}
      </div>
    </div>
    {(computers.length !== 0 || iosDevices.length !== 0) && (
      <div className="flex flex-col xs:flex-row rounded-b-xl p-4 space-y-3 xs:space-y-0 xs:space-x-3">
        <Button
          type="link"
          color="tertiary"
          to={`${id}/activity`}
          className="w-[100%] xs:basis-1/2"
          disabled={computers.length === 0}
          size="large"
        >
          <i className="fa-solid fa-binoculars mr-2" /> Mac activity
        </Button>
        <Button
          type="link"
          color="secondary"
          to={id}
          testId="edit-user"
          className="w-[100%] xs:basis-1/2"
        >
          <i className="fa-solid fa-cog mr-2" /> Settings
        </Button>
      </div>
    )}
  </div>
);

export default ChildCard;
