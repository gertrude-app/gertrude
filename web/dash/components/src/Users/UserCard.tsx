import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';
import { inflect } from '@dash/utils';
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
  <div className="rounded-xl border-[0.5px] flex flex-col justify-between shadow-lg w-full bg-white sm:min-w-[400px]">
    <div className="p-5">
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-black text-gray-700 mr-3">{name}</h1>
        <div className="flex items-center space-x-4">
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              screenshotsEnabled
                ? `bg-violet-200 text-violet-600`
                : `bg-gray-100 text-gray-300`,
            )}
          >
            <i className="fa-solid fa-camera" />
          </div>
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              keystrokesEnabled
                ? `bg-violet-200 text-violet-600`
                : `bg-gray-100 text-gray-300`,
            )}
          >
            <i className="fa-solid fa-keyboard" />
          </div>
        </div>
      </div>
      <div className="flex justify-start items-center mb-4 mt-0.5">
        <p className="text-gray-400">
          <span className="font-medium text-gray-500">{numKeychains}</span> keychains •{` `}
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
      <div className="flex justify-center my-3">
        <Button
          type="button"
          color="secondary"
          onClick={addDevice}
          small
          className="mt-2"
        >
          <i className="fa-solid fa-plus mr-2" /> Add device
        </Button>
      </div>
    </div>
    <div className="border-t flex rounded-b-xl divide-x divide-gray-200 hover:divide-gray-300/80">
      <Link
        to={id}
        className="ScrollTop transition duration-100 w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-50 rounded-bl-xl"
      >
        <i className="fa fa-pen text-sm mr-3 text-gray-600" aria-hidden="true" />
        <h2 className="text-gray-500 text-lg tracking-wide">Edit</h2>
      </Link>
      <Link
        to={`${id}/activity`}
        className="ScrollTop transition duration-100 w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-50 rounded-br-xl"
      >
        <i className="fa fa-binoculars text-lg mr-3 text-gray-600" aria-hidden="true" />
        <span className="text-gray-500 text-lg tracking-wide">Activity</span>
      </Link>
    </div>
  </div>
);

export default UserCard;
