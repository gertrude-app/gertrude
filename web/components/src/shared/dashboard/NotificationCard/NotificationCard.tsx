import React, { useState } from 'react';
import cx from 'classnames';
import SelectMenu from '../../SelectMenu';
import Button from '../../Button';

type WhenToSend = 'suspension requests' | 'unlock requests';

type HowToSend =
  | { method: 'email'; email: string }
  | { method: 'text'; number: string }
  | { method: 'slack'; channelName: string };

type Props = HowToSend & { when: WhenToSend };

// will need more props for the select menu stuff to work
const NotificationCard: React.FC<Props> = (props) => {
  const [open, setOpen] = useState(false);

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
      <div
        className={cx(
          `p-4 space-y-4 -mt-4 [transition:150ms]`,
          open ? 'h-56' : 'h-0 opacity-0 overflow-hidden',
        )}
      >
        <div>
          <h3 className="mb-1 text-violet-800 font-medium text-md ml-1">Method:</h3>
          <SelectMenu
            options={['Email me@example.com', 'Text (123) 456-7890', 'Slack #Gertrude']}
            selectedOption={'Email me@example.com'}
            setSelected={() => {}}
          />
        </div>
        <div>
          <h3 className="mb-1 text-violet-800 font-medium text-md ml-1">Upon:</h3>
          <SelectMenu
            options={['Suspension requests', 'Unlock requests']}
            selectedOption={'Suspension requests'}
            setSelected={() => {}}
          />
        </div>
      </div>
      <div className="bg-gray-100 rounded-b-xl flex justify-end items-center p-3">
        <Button
          type="button"
          onClick={() => setOpen(true)}
          color="secondary-white"
          small
          className={`${open ? 'hidden' : 'block'}`}
        >
          <i className="fa fa-pen mr-3" />
          Edit
        </Button>
        <Button
          type="button"
          onClick={() => {}}
          color="secondary-warning"
          small
          className={`${open ? 'hidden' : 'block'} ml-3`}
        >
          <i className="fa fa-trash mr-3" />
          Delete
        </Button>
        <Button
          type="button"
          onClick={() => setOpen(false)}
          color="secondary-white"
          small
          className={`${open ? 'block' : 'hidden'} mr-3`}
        >
          Cancel
        </Button>
        <Button
          type="button"
          onClick={() => {}}
          color="primary-violet"
          small
          className={`${open ? 'block' : 'hidden'}`}
        >
          Save
        </Button>
      </div>
    </div>
  );
};

export default NotificationCard;
