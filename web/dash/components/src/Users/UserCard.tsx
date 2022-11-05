import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';
import { inflect } from '@dash/utils';
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
  <div className="rounded-xl border flex flex-col justify-between shadow-lg w-full bg-white sm:min-w-[400px]">
    <div className="p-5">
      <h1 className="text-3xl font-black text-gray-700 m-2 pb-4 mb-6 border-b">{name}</h1>
      <div className="flex items-center mt-3 ml-2">
        <i className="fa fa-key text-gray-400 text-lg" />
        <h3 className="ml-3 text-gray-600">
          <span className="text-lg font-bold">{numKeychains}</span>
          {` `}
          {inflect(`keychain`, numKeychains)},{` `}
          <span className="text-lg font-bold">{numKeys}</span>
          {` `}
          {inflect(`key`, numKeys)}
        </h3>
      </div>
      <div className="flex items-center mt-1 ml-2">
        <i className="fa fa-camera text-gray-400" />
        <h3 className="text-gray-600 ml-3">
          Screenshots:{` `}
          <span
            className={cx(
              `text-lg font-bold`,
              screenshotsEnabled ? `text-violet-600` : `text-gray-600`,
            )}
          >
            {screenshotsEnabled ? `enabled` : `disabled`}
          </span>
        </h3>
      </div>
      <div className="flex items-center my-1 ml-2">
        <i className="fa fa-keyboard text-gray-400" />
        <h3 className="text-gray-600 ml-3">
          Keystrokes:{` `}
          <span
            className={cx(
              `text-lg font-bold`,
              keystrokesEnabled ? `text-violet-600` : `text-gray-600`,
            )}
          >
            {keystrokesEnabled ? `monitored` : `not monitored`}
          </span>
        </h3>
      </div>
      {devices.length ? (
        <>
          <div className="text-lg mt-4 -mb-4">
            <p>
              <span className="text-xl font-bold">{devices.length}</span>
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
      <div className="flex justify-center mt-2">
        <button
          onClick={addDevice}
          className="mt-1 text-violet-600 px-7 py-2 rounded-lg hover:bg-gray-100 self-center transition duration-100"
        >
          <i className="fa fa-plus mr-2" />
          Add device
        </button>
      </div>
    </div>
    <div className="border-t flex bg-gray-100 rounded-b-xl divide-x divide-gray-200 hover:divide-gray-300/80">
      <Link
        to={id}
        className="ScrollTop w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-200 rounded-bl-xl"
      >
        <i className="fa fa-pen text-sm mr-3 text-gray-600" aria-hidden="true" />
        <h2 className="text-gray-500 text-[16px] tracking-wide">Edit</h2>
      </Link>
      <Link
        to={`${id}/activity`}
        className="ScrollTop w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-200 rounded-br-xl"
      >
        <i className="fa fa-binoculars text-lg mr-3 text-gray-600" aria-hidden="true" />
        <span className="text-gray-500 text-[16px] tracking-wide">Activity</span>
      </Link>
    </div>
  </div>
);

export default UserCard;
