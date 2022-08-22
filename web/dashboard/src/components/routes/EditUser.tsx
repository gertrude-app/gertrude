import TextInput from '@shared/dashboard/TextInput';
import Toggle from '@shared/dashboard/Toggle';
import UserDevice from '@shared/dashboard/Users/UserDevice';
import React, { useState } from 'react';

const EditUser: React.FC = () => {
  // temp state:
  const [title, setTitle] = useState('John Doe');
  const [resolution, setResolution] = useState('1000');
  const [frequency, setFrequency] = useState('60');
  const [keylogging, setKeylogging] = useState(false);
  const [screenshots, setScreenshots] = useState(false);
  const devices: Array<{
    id: string;
    model: string;
    status: 'offline' | 'online';
    icon: 'laptop' | 'desktop';
  }> = [
    { id: 'abc123', model: '14" MacBook Pro', status: 'offline', icon: 'laptop' },
    { id: 'def456', model: 'Mac Studio', status: 'online', icon: 'desktop' },
    { id: 'ghi789', model: 'iMac', status: 'online', icon: 'desktop' },
  ];

  return (
    <div className="py-4 lg:px-4 relative max-w-3xl">
      <h1 className="text-3xl font-inter text-gray-800">Edit user</h1>
      <div className="mt-6">
        <TextInput
          type={'text'}
          label={'Title:'}
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
          <button className="mt-5 text-violet-600 px-7 py-2 rounded-lg hover:bg-gray-100 self-end transition duration-100">
            <i className="fa fa-plus mr-2" />
            Add device
          </button>
        </div>
        <div className="mt-4">
          <h2 className="text-lg font-bold text-gray-700">Monitoring</h2>
          <div className="flex justify-between items-center bg-gray-100 my-3 p-6 rounded-xl">
            <div>
              <h3 className="font-medium text-gray-700">Enable keylogging</h3>
              <p className="text-gray-500 text-sm">
                Sends reports of all keystrokes to your review
              </p>
            </div>
            <Toggle enabled={keylogging} setEnabled={setKeylogging} />
          </div>
          <div
            className={`bg-gray-100 my-3 p-6 rounded-xl overflow-hidden relative [transition:150ms] ${
              screenshots ? 'h-[200px]' : 'h-[90px]'
            }`}
          >
            <div className="flex justify-between items-center">
              <div>
                <h3 className="font-medium text-gray-700">Enable screenshots</h3>
                <p className="text-gray-500 text-sm">
                  Periodically take a screenshot and upload for your review
                </p>
              </div>
              <Toggle enabled={screenshots} setEnabled={setScreenshots} />
            </div>
            <div
              className={`flex mt-5 transition duration-150 ${
                screenshots ? 'opacity-100' : 'opacity-0'
              }`}
            >
              <TextInput
                type={'number'}
                label={'Resolution'}
                value={resolution}
                setValue={setResolution}
                unit="pixels"
                className="mr-3"
              />
              <TextInput
                type={'number'}
                label={'Frequency'}
                value={frequency}
                setValue={setFrequency}
                unit="seconds"
                className="ml-3"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditUser;
