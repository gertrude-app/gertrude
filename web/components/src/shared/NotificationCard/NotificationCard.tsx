import React, { useState } from 'react';
import Button from '../Button';
import SelectMenu from '../SelectMenu';
import TextInput from '../TextInput';

interface Props {
  whenToNotify: string;
  setWhenToNotify: (whenToNotify: string) => void;
  howToNotify: string;
  setHowToNotify: (howToNotify: string) => void;
}

const NotificationCard: React.FC<Props> = ({
  whenToNotify,
  setWhenToNotify,
  howToNotify,
  setHowToNotify,
}) => {
  let notificationInputs: {
    label: string;
    value: string;
    setValue(arg: string): void;
    type: 'email' | 'text';
  }[] = [];

  switch (howToNotify) {
    case `Send a Slack`:
      notificationInputs = [
        {
          type: `text`,
          label: `Channel ID:`,
          value: `CE07D6SDX89201`,
          setValue: () => {},
        },
        {
          type: `text`,
          label: `Bot token:`,
          value: `abc-1234567890-xc123231231231`,
          setValue: () => {},
        },
      ];
      break;
    case `Send an email`:
      notificationInputs = [
        {
          type: `email`,
          label: `Email address:`,
          value: `foo@example.com`,
          setValue: () => {},
        },
      ];
      break;
    case `Send a text message`:
      notificationInputs = [
        {
          type: `text`,
          label: `Phone number:`,
          value: `(123) 456-7890`,
          setValue: () => {},
        },
      ];
      break;
  }

  return (
    <div className="bg-white p-8 rounded-xl shadow-md border my-4 relative overflow-hidden border-t-4 border-t-violet-500 max-w-5xl">
      <div className="flex flex-col items-stretch relative z-20">
        <h3 className="mb-2 text-gray-600 text-sm">Notify me upon:</h3>
        <SelectMenu
          options={[`Unlock requests`, `Filter suspension requests`]}
          selectedOption={whenToNotify}
          setSelected={setWhenToNotify}
        />
        <h3 className="mt-4 mb-2 text-gray-600 text-sm">Via:</h3>
        <SelectMenu
          options={[`Send a Slack`, `Send an email`, `Send a text message`]}
          selectedOption={howToNotify}
          setSelected={setHowToNotify}
        />
      </div>
      <div className="flex flex-col sm:flex-row mt-8 relative z-10 space-y-4 sm:space-y-0 sm:space-x-4">
        {notificationInputs.map((input) => (
          <div className="flex-grow">
            <h3 className="mb-1 text-gray-600 text-sm">{input.label}</h3>
            <TextInput
              type={input.type}
              label={``}
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
        <Button color="secondary-warning" type="button" onClick={() => {}} small>
          Delete
        </Button>
      </div>
    </div>
  );
};

const NotificationCardContainer: React.FC = () => {
  const [whenToNotify, setWhenToNotify] = useState(`Unlock requests`);
  const [howToNotify, setHowToNotify] = useState(`Send a Slack`);
  return (
    <NotificationCard
      whenToNotify={whenToNotify}
      setWhenToNotify={setWhenToNotify}
      howToNotify={howToNotify}
      setHowToNotify={setHowToNotify}
    />
  );
};

export default NotificationCardContainer;
