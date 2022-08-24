import React, { useState } from 'react';
import cx from 'classnames';
import Button from '@shared/Button';
import KeychainCard from '@shared/dashboard/KeychainCard';
import TextInput from '@shared/dashboard/TextInput';
import Toggle from '@shared/dashboard/Toggle';
import UserDevice from '@shared/dashboard/Users/UserDevice';
import PageHeading from '@shared/dashboard/PageHeading';

const EditUser: React.FC = () => {
  // temp state:
  const [title, setTitle] = useState(`John Doe`);
  const [resolution, setResolution] = useState(`1000`);
  const [frequency, setFrequency] = useState(`60`);
  const [keylogging, setKeylogging] = useState(false);
  const [screenshots, setScreenshots] = useState(false);
  const devices: Array<{
    id: string;
    model: string;
    status: 'offline' | 'online';
    icon: 'laptop' | 'desktop';
  }> = [
    { id: `abc123`, model: `14" MacBook Pro`, status: `offline`, icon: `laptop` },
    { id: `def456`, model: `Mac Studio`, status: `online`, icon: `desktop` },
    { id: `ghi789`, model: `iMac`, status: `online`, icon: `desktop` },
  ];

  return (
    <div className="py-4 lg:px-4 relative max-w-3xl">
      <PageHeading icon={`pen`}>Edit user</PageHeading>
      <div className="mt-8">
        <TextInput
          type={`text`}
          label={`Title:`}
          value={title}
          setValue={setTitle}
          className="max-w-xl"
        />
        <h2 className="mt-5 text-lg font-bold text-gray-700">3 devices:</h2>
        <div className="flex flex-col">
          {devices.map((device) => (
            <div key={device.id} className="flex items-center mt-3">
              <UserDevice
                model={device.model}
                status={device.status}
                icon={device.icon}
                className="flex-grow mr-3"
              />
              <div className="transition duration-100 flex justify-center items-center w-10 h-10 rounded-full hover:bg-gray-100 cursor-pointer text-gray-500 hover:text-red-500">
                <i className="fa fa-trash" />
              </div>
            </div>
          ))}
          <button className="mt-5 text-violet-700 font-medium px-7 py-2 rounded-lg hover:bg-violet-100 self-end transition duration-100">
            <i className="fa fa-plus mr-2" />
            Add device
          </button>
        </div>
        <div className="mt-4">
          <h2 className="text-lg font-bold text-gray-700">Monitoring</h2>
          <div className="flex justify-between items-center bg-gray-100 my-3 p-4 sm:p-6 rounded-xl">
            <div className="mr-3">
              <h3 className="font-medium text-gray-700">Enable keylogging</h3>
              <p className="text-gray-500 text-sm">
                Sends reports of all keystrokes to your review
              </p>
            </div>
            <Toggle enabled={keylogging} setEnabled={setKeylogging} />
          </div>
          <div
            className={`bg-gray-100 my-3 p-4 sm:p-6 rounded-xl overflow-hidden relative [transition:150ms]`}
          >
            <div className="flex justify-between items-center">
              <div className="mr-3">
                <h3 className="font-medium text-gray-700">Enable screenshots</h3>
                <p className="text-gray-500 text-sm">
                  Periodically take a screenshot and upload for your review
                </p>
              </div>
              <Toggle enabled={screenshots} setEnabled={setScreenshots} />
            </div>
            <div
              className={cx(
                `flex flex-col lg+:flex-row mt-5 transition duration-100`,
                screenshots ? `opacity-100` : `opacity-0 hidden`,
              )}
            >
              <TextInput
                type={`number`}
                label={`Resolution`}
                value={resolution}
                setValue={setResolution}
                unit="pixels"
                className="lg+:mr-3"
              />
              <TextInput
                type={`number`}
                label={`Frequency`}
                value={frequency}
                setValue={setFrequency}
                unit="seconds"
                className="mt-3 lg+:mt-0 lg+:ml-3"
              />
            </div>
          </div>
        </div>
        <div className="mt-12">
          <h2 className="text-lg font-bold text-gray-700">Keychains</h2>
          <div className="p-3 flex flex-col space-y-4">
            <KeychainCard shared={true} name={`UA Brightspace`} keys={74} />
            <KeychainCard shared={true} name={`HTC`} keys={123} />
            <KeychainCard shared={false} name={`Jason's blog`} keys={2} />
            <KeychainCard shared={false} name={`John Doe's stuff`} keys={22} />
            <KeychainCard shared={true} name={`Microsoft Word`} keys={1234} />
            <button className="mt-5 text-violet-700 font-medium px-7 py-2 rounded-lg hover:bg-violet-100 self-end transition duration-100">
              <i className="fa fa-plus mr-2" />
              Add keychain
            </button>
          </div>
          <div className="flex mt-5 justify-end border-t-2 pt-8">
            <Button
              type="button"
              onClick={() => {}}
              color="secondary-warning"
              className="mr-5"
              small
            >
              Delete user
            </Button>
            <Button
              small
              type="button"
              onClick={() => {}}
              color="primary-violet"
              className=""
            >
              Save user
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditUser;
