import React from 'react';

type Props =
  | { method: 'email'; address: string }
  | {
      method: 'slack';
      channel: string;
    }
  | { method: 'text'; number: string };

const NotificationMethod: React.FC<Props> = (props) => (
  <li className="px-4 py-2 flex justify-between items-center odd:bg-gray-100 rounded-lg max-w-4xl">
    <h2 className="text-gray-700 capitalize">
      {props.method}
      {` `}
      <span className="text-violet-700 font-medium">me@example.com</span>
    </h2>
    <div className="w-10 h-10 rounded-full cursor-pointer transition duration-75 bg-black bg-opacity-0 hover:bg-opacity-5 flex justify-center items-center mr-2">
      <i className="fa fa-trash text-red-400" />
    </div>
  </li>
);

export default NotificationMethod;
