import React from 'react';

type Props = {
  shared: boolean;
  name: string;
  keys: number;
};

const KeychainCard: React.FC<Props> = ({ shared, name, keys }) => (
  <div className="p-4 pl-6 border shadow-lg rounded-xl bg-white flex flex-row items-center">
    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-indigo-400 to-fuchsia-500 text-white flex justify-center items-center text-xl mr-6">
      <i className={`fa fa-key`} />
    </div>
    <div className="flex-grow">
      <div className="flex justify-between mb-2">
        <h1 className="font-bold text-lg">{name}</h1>
        <p className="text-gray-500">
          <span className="font-bold text-gray-600">{keys}</span> keys
        </p>
      </div>
      <div className="flex justify-between items-center">
        <h3
          className={`${!shared ? `text-gray-500` : `text-green-600 flex items-center`}`}
        >
          <i className={`fa fa-${shared ? `users` : `user`} mr-2 text-sm`} />
          {shared ? `Public` : `Private`}
        </h3>
        <button className="text-red-500 px-3 py-1 hover:bg-red-50 transition duration-100 rounded-lg outline-none focus:ring-2 ring-red-400">
          Delete
        </button>
      </div>
    </div>
  </div>
);

export default KeychainCard;
