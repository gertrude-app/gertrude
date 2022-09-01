import React from 'react';

type Props = {
  onDelete(): unknown;
  method: 'email' | 'slack' | 'text';
  value: string;
};

const NotificationMethod: React.FC<Props> = ({ onDelete, method, value }) => (
  <li className="px-4 py-2 flex justify-between items-center odd:bg-gray-100 rounded-lg max-w-4xl">
    <h2 className="text-gray-700">
      <span className="capitalize">{method}</span>
      <span className="text-violet-700 font-medium pl-1.5">{value}</span>
    </h2>
    <button
      onClick={onDelete}
      className="w-10 h-10 rounded-full cursor-pointer transition duration-75 bg-black bg-opacity-0 hover:bg-opacity-5 flex justify-center items-center mr-2"
    >
      <i className="fa fa-trash text-red-400" />
    </button>
  </li>
);

export default NotificationMethod;
