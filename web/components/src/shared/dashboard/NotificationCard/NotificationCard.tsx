import React from 'react';
import Button from '../../Button';

type WhenToSend = 'suspension requests' | 'unlock requests';

type HowToSend =
  | { method: 'email'; email: string }
  | { method: 'text'; number: string }
  | { method: 'slack'; botToken: string; channelId: string; channelName: string };

type Props = HowToSend & { when: WhenToSend };

const NotificationCard: React.FC<Props> = (props) => {
  let icon = '';
  let text = <h2></h2>;
  switch (props.method) {
    case 'email':
      text = (
        <h2 className="text-gray-700 text-lg">
          Email <span className="font-bold">{props.email}</span> for{' '}
          <span className="text-gray-900">{props.when}</span>
        </h2>
      );
      icon = 'envelope';
      break;
    case 'text':
      text = (
        <h2 className="text-gray-700 text-lg">
          Text <span className="font-bold">{props.number}</span> for{' '}
          <span className="text-gray-900">{props.when}</span>
        </h2>
      );
      icon = 'mobile';
      break;
    case 'slack':
      text = (
        <h2 className="text-gray-700 text-lg">
          Slack <span className="font-bold">{props.channelName}</span> for{' '}
          <span className="text-gray-900">{props.when}</span>
        </h2>
      );
      icon = 'slack';
      break;
  }

  return (
    <div className="shadow-lg border rounded-xl w-full sm:w-128 flex flex-col bg-white m-2 sm:m-4">
      <div className="p-5">
        <i
          className={`fa fa-${icon} text-2xl mb-4 bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent [-webkit-background-clip:text;] w-min`}
        />
        {text}
      </div>
      <div className="bg-gray-100 rounded-b-xl flex justify-end items-center p-3">
        <Button type="button" onClick={() => {}} color="secondary-white" small>
          <i className="fa fa-pen mr-3" />
          Edit
        </Button>
      </div>
    </div>
  );
};

export default NotificationCard;
