import React from 'react';
import cx from 'classnames';
import inflect from '../lib/inflect';
import UserDevice from '../UserDevice';

type Props = {
  title: string;
  keys: number;
  keychains: number;
  devices: { title: string; status: 'online' | 'offline' }[];
  screenshots: boolean;
  keystrokes: boolean;
};

const UserCard: React.FC<Props> = ({
  title,
  keys,
  keychains,
  devices,
  screenshots,
  keystrokes,
}) => (
  <div className="rounded-xl border shadow-lg w-full xl:w-112 my-4 mx-0 md:mx-4 bg-white">
    <div className="p-5">
      <h1 className="text-3xl font-black text-gray-700 m-2 pb-4 mb-6 border-b">
        {title}
      </h1>
      <div className="flex items-center mt-3 ml-2">
        <i className="fa fa-key text-gray-400 text-lg" />
        <h3 className="ml-3 text-gray-600">
          <span className="text-lg font-bold">{keychains}</span>{' '}
          {inflect('keychain', keychains)},{' '}
          <span className="text-lg font-bold">{keys}</span>
          {` `}
          {inflect('key', keys)}
        </h3>
      </div>
      <div className="flex items-center mt-1 ml-2">
        <i className="fa fa-camera text-gray-400" />
        <h3 className="text-gray-600 ml-3">
          Screenshots:{` `}
          <span
            className={cx(
              `text-lg font-bold`,
              screenshots ? `text-violet-600` : `text-gray-600`,
            )}
          >
            {screenshots ? `enabled` : `disabled`}
          </span>
        </h3>
      </div>
      <div className="flex items-center mt-1 ml-2">
        <i className="fa fa-keyboard text-gray-400" />
        <h3 className="text-gray-600 ml-3">
          Keystrokes:{` `}
          <span
            className={cx(
              `text-lg font-bold`,
              keystrokes ? `text-violet-600` : `text-gray-600`,
            )}
          >
            {keystrokes ? `monitored` : `not monitored`}
          </span>
        </h3>
      </div>
      {devices.length ? (
        <div>
          <div className="text-lg mt-4 -mb-4">
            <p>
              <span className="text-xl font-bold">{devices.length}</span> device
              {devices.length === 1 ? `` : `s`}:
            </p>
          </div>
          <div className="flex flex-col mt-3">
            {devices.map((device) => (
              <UserDevice key={device.title} type={device.title} status={device.status} />
            ))}
            <button className="mt-3 text-gray-600 hover:text-gray-800 px-7 py-2 rounded-lg hover:bg-gray-100 self-center transition duration-100">
              <i className="fa fa-plus mr-3" />
              Add device
            </button>
          </div>
        </div>
      ) : (
        <div className="flex flex-col items-center">
          <h2 className="text-lg mt-4 font-medium text-gray-700 self-start">
            No devices
          </h2>
          <button className="mt-1 text-gray-600 hover:text-gray-800 px-7 py-2 rounded-lg hover:bg-gray-100 self-center transition duration-100">
            <i className="fa fa-plus mr-3" />
            Add device
          </button>
        </div>
      )}
    </div>
    <div className="border-t flex bg-gray-50 rounded-b-xl">
      <button className="w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-100 rounded-bl-xl">
        <i className="fa fa-pen text-lg mr-3 text-gray-500" />
        <h2 className="text-gray-800">Edit</h2>
      </button>
      <button className="w-1/2 py-3 text-xl flex items-center justify-center hover:bg-gray-100 rounded-br-xl">
        <i className="fa fa-binoculars text-lg mr-3 text-gray-500" />
        <h2 className="text-gray-800">Monitor</h2>
      </button>
    </div>
  </div>
);

export default UserCard;
