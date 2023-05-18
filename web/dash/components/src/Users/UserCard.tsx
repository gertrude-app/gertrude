import React from 'react';
import cx from 'classnames';
import { inflect } from '@shared/string';
import { Button } from '@shared/components';
import type { Subcomponents } from '@dash/types';
import UserDevice from './UserDevice';

type Props = {
  id: string;
  name: string;
  numKeys: number;
  numKeychains: number;
  devices: Subcomponents<typeof UserDevice>;
  screenshotsEnabled: boolean;
  keystrokesEnabled: boolean;
  addDevice(): unknown;
};

const UserCard: React.FC<Props> = ({
  id,
  name,
  numKeys,
  numKeychains,
  devices,
  screenshotsEnabled,
  keystrokesEnabled,
  addDevice,
}) => (
  <div
    className="rounded-xl border-[0.5px] flex flex-col justify-between shadow-lg w-full bg-white sm:min-w-[400px]"
    data-test="user-card"
  >
    <div className="p-5">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-black text-gray-700 mr-3">{name}</h1>
        <div className="flex items-center space-x-4">
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              screenshotsEnabled
                ? `bg-indigo-100 text-indigo-500`
                : `bg-gray-100 text-gray-300`,
            )}
          >
            <i className="fa-solid fa-camera" />
          </div>
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              keystrokesEnabled
                ? `bg-indigo-100 text-indigo-500`
                : `bg-gray-100 text-gray-300`,
            )}
          >
            <i className="fa-solid fa-keyboard" />
          </div>
        </div>
      </div>
      <div className="flex justify-start items-center mb-4 mt-0.5">
        <p className="text-gray-400">
          <span className="font-medium text-gray-500">{numKeychains}</span> keychains •
          {` `}
          <span className="font-medium text-gray-500">{numKeys}</span> keys
        </p>
      </div>
      {devices.length ? (
        <>
          <div className="text-lg mt-4 -mb-4">
            <p className="text-gray-500">
              <span className="text-xl font-bold text-gray-600">{devices.length}</span>
              {` `}
              {inflect(`device`, devices.length)}:
            </p>
          </div>
          <div className="flex flex-col mt-3 space-y-3 pt-3">
            {devices.map((device) => (
              <UserDevice
                key={device.id}
                model={device.model}
                status={device.status}
                icon={device.icon}
              />
            ))}
          </div>
        </>
      ) : (
        <div className="flex flex-col items-center">
          <h2 className="text-lg mt-4 font-medium text-gray-700 self-start">
            No devices
          </h2>
        </div>
      )}
      <div
        className={`flex ${
          devices.length === 0 ? `justify-center` : `justify-end`
        } mt-3 mr-2`}
      >
        {devices.length > 0 ? (
          <button
            className="w-8 h-8 rounded-full bg-violet-50 flex justify-center items-center text-violet-400 text-lg hover:bg-violet-100 transition duration-100 hover:text-violet-500"
            onClick={addDevice}
          >
            <i className="fa-solid fa-plus" />
          </button>
        ) : (
          <Button type="button" color="secondary" onClick={addDevice} size="large">
            <i className="fa-solid fa-plus mr-2" /> Add a device
          </Button>
        )}
      </div>
    </div>
    <div className="flex flex-col xs:flex-row rounded-b-xl p-3 space-y-3 xs:space-y-0 xs:space-x-3">
      <Button
        type="link"
        color="tertiary"
        to={id}
        testId="edit-user"
        className="flex-grow w-[100%] xs:w-auto"
      >
        <i className="fa-solid fa-pen mr-2" /> Edit
      </Button>
      <Button
        type="link"
        color="secondary"
        to={`${id}/activity`}
        className="flex-grow w-[100%] xs:w-auto"
        disabled={devices.length === 0}
        size="large"
      >
        <i className="fa-solid fa-binoculars mr-2" /> Activity
      </Button>
    </div>
  </div>
);

export default UserCard;
