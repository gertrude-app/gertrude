import React from 'react';
import PillBadge from '../../PillBadge';

export type Props = {
  model: string;
  status: 'online' | 'offline';
  icon: 'desktop' | 'laptop';
};

const UserDevice: React.FC<Props> = ({ model, status, icon }) => (
  <div className="border rounded-full p-2 pr-4 shadow bg-white hover:bg-gray-50 cursor-pointer duration-75 transition mt-3">
    <div className="flex justify-between items-center">
      <div className="flex items-center">
        <div className="flex justify-center items-center w-10 h-10 mr-3 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full">
          <i className={`fas fa-${icon} text-white text-opacity-80`} />
        </div>
        <h3 className="text-gray-500 text-lg font-medium">{model}</h3>
      </div>
      {status === `online` && (
        <>
          <PillBadge type="green" className="items-center hidden sm:flex">
            <li className="fa fa-circle mr-2 text-xs text-green-500" />
            online
          </PillBadge>
          <div className="block sm:hidden">
            <li className="fa fa-circle text-sm text-green-400 mr-2" />
          </div>
        </>
      )}
    </div>
  </div>
);

export default UserDevice;
