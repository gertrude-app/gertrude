import Button from '@shared/Button';
import SelectMenu from '@shared/SelectMenu';
import TextInput from '@shared/TextInput';
import React, { useState } from 'react';

const NotificationCard: React.FC = () => {
  // TEMP
  const [whenToNotify, setWhenToNotify] = useState('Unlock requests');
  const [howToNotify, setHowToNotify] = useState('Send a Slack');

  let notificationInputs: {
    label: string;
    value: string;
    setValue(arg: string): void;
    type: 'email' | 'text';
  }[] = [];

  switch (howToNotify) {
    case 'Send a Slack':
      notificationInputs = [
        {
          type: 'text',
          label: 'Channel ID:',
          value: 'CE07D6SDX89201',
          setValue: () => {},
        },
        {
          type: 'text',
          label: 'Bot token:',
          value: 'abc-1234567890-xc123231231231',
          setValue: () => {},
        },
      ];
      break;
    case 'Send an email':
      notificationInputs = [
        {
          type: 'email',
          label: 'Email address:',
          value: 'foo@example.com',
          setValue: () => {},
        },
      ];
      break;
    case 'Send a text message':
      notificationInputs = [
        {
          type: 'text',
          label: 'Phone number:',
          value: '(123) 456-7890',
          setValue: () => {},
        },
      ];
      break;
  }

  return (
    <div className="bg-white p-8 rounded-xl shadow-md border my-4 relative overflow-hidden border-t-4 border-t-violet-500">
      <div className="flex flex-col items-stretch relative z-20">
        <h3 className="mb-1 text-gray-700">Notify me upon:</h3>
        <SelectMenu
          options={['Unlock requests', 'Filter suspension requests']}
          selectedOption={whenToNotify}
          setSelected={setWhenToNotify}
        />
        <h3 className="mt-3 mb-1 text-gray-700">Via:</h3>
        <SelectMenu
          options={['Send a Slack', 'Send an email', 'Send a text message']}
          selectedOption={howToNotify}
          setSelected={setHowToNotify}
        />
      </div>
      <div className="flex flex-col sm:flex-row mt-8 relative z-10 space-y-4 sm:space-y-0 sm:space-x-4">
        {notificationInputs.map((input) => (
          <div className="flex-grow">
            <h3 className="mb-1 text-gray-700">{input.label}</h3>
            <TextInput
              type={input.type}
              label={''}
              value={input.value}
              setValue={input.setValue}
            />
          </div>
        ))}
      </div>
      <div className="flex justify-end items-center mt-8 border-t-2 pt-7 relative z-10">
        <Button
          color="secondary-white"
          type="button"
          onClick={() => {}}
          small
          className="mr-4"
        >
          Duplicate
        </Button>
        <Button color="secondary-severe" type="button" onClick={() => {}} small>
          Delete
        </Button>
      </div>
    </div>
  );
};

export default NotificationCard;
