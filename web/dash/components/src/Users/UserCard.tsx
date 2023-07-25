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
    className="rounded-3xl border-[0.5px] border-slate-200 flex flex-col justify-between shadow-lg shadow-slate-300/50 bg-white sm:min-w-[400px]"
    data-test="user-card"
  >
    <div className="p-6">
      <div className="flex justify-between items-center">
        <h2 className="text-3xl font-extrabold text-slate-700 mr-3">{name}</h2>
        <div className="flex items-center space-x-4">
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              screenshotsEnabled
                ? `bg-indigo-100 text-indigo-500`
                : `bg-slate-100 text-slate-300`,
            )}
          >
            <i className="fa-solid fa-camera" />
          </div>
          <div
            className={cx(
              `w-9 h-9 rounded-full flex justify-center items-center text-lg`,
              keystrokesEnabled
                ? `bg-indigo-100 text-indigo-500`
                : `bg-slate-100 text-slate-300`,
            )}
          >
            <i className="fa-solid fa-keyboard" />
          </div>
        </div>
      </div>
      <div className="flex justify-start items-center mb-4 mt-0.5">
        <p className="text-slate-500">
          <span className="font-semibold text-slate-600">{numKeychains}</span> keychains •
          {` `}
          <span className="font-semibold text-slate-600">{numKeys}</span> keys
        </p>
      </div>
      {devices.length ? (
        <>
          <div className="text-lg mt-4 -mb-4">
            <p className="text-slate-500">
              <span className="text-xl font-bold text-slate-600">{devices.length}</span>
              {` `}
              {inflect(`computer`, devices.length)}:
            </p>
          </div>
          <div className="flex flex-col mt-3 space-y-3 pt-3">
            {devices.map((device) => (
              <UserDevice
                key={device.id}
                id={device.id}
                modelTitle={device.modelTitle}
                modelIdentifier={device.modelIdentifier}
                name={device.name}
                status={device.status}
              />
            ))}
          </div>
        </>
      ) : (
        <div className="bg-slate-50 p-6 flex flex-col justify-center items-center rounded-xl">
          <h2 className="text-xl font-medium text-slate-500 mb-4">No devices</h2>
          <Button type="button" color="secondary" onClick={addDevice} size="large">
            <i className="fa-solid fa-plus mr-2" /> Add a device
          </Button>
        </div>
      )}
      <div
        className={`flex ${
          devices.length === 0 ? `justify-center` : `justify-end`
        } mt-3 mr-2`}
      >
        {devices.length > 0 && (
          <button
            className="w-8 h-8 rounded-full bg-violet-50 flex justify-center items-center text-violet-400 text-lg hover:bg-violet-100 transition duration-100 hover:text-violet-500"
            onClick={addDevice}
          >
            <i className="fa-solid fa-plus" />
          </button>
        )}
      </div>
    </div>
    <div className="flex flex-col xs:flex-row rounded-b-xl p-4 space-y-3 xs:space-y-0 xs:space-x-3">
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
