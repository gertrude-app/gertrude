import React, { useState } from 'react';
import cx from 'classnames';
import Button from '../../Button';
import SelectMenu from '../../SelectMenu';
import TextInput from '../../TextInput';

type Props = {
  open: boolean;
  setOpen(open: boolean): void;
};

const EditNotificationSidebar: React.FC<Props> = ({ open, setOpen }) => {
  const [selectedMethod, setSelectedMethod] = useState('Email');
  const [address, setAddress] = useState('');
  let addressType = '';
  switch (selectedMethod) {
    case 'Email':
      addressType = 'Email address';
      break;
    case 'Text':
      addressType = 'Phone number';
      break;
  }

  return (
    <div
      className={cx(
        `fixed bg-white top-0 right-0 w-96 h-screen border-l shadow-xl [transition:150ms] z-30 flex flex-col justify-beween`,
        open ? `mr-0` : `-mr-112`,
      )}
    >
      <div className="p-8 flex-grow flex flex-col">
        <h2 className="text-2xl font-black text-gray-700 mb-8">
          New notification method
        </h2>
        <label className="mb-2 text-gray-500 text-lg font-medium block">Method:</label>
        <SelectMenu
          options={['Email', 'Text', 'Slack']}
          selectedOption={selectedMethod}
          setSelected={setSelectedMethod}
        />
        {selectedMethod !== 'Slack' ? (
          <>
            <label className="mb-2 text-gray-500 text-lg font-medium block mt-6">
              {addressType}:
            </label>
            <TextInput type={'text'} value={address} setValue={setAddress} label={''} />
            <Button
              type="button"
              onClick={() => setOpen(false)}
              color="secondary-white"
              small
              className="self-end mt-4"
            >
              Send code
            </Button>
          </>
        ) : (
          ''
        )}
      </div>
      <div className="px-6 py-4 flex justify-center space-x-4">
        <Button
          type="button"
          onClick={() => setOpen(false)}
          color="secondary-white"
          className="flex-grow"
        >
          Cancel
        </Button>
        <Button
          type="button"
          onClick={() => {}}
          color="primary-violet"
          className="flex-grow"
        >
          Save
        </Button>
      </div>
    </div>
  );
};

export default EditNotificationSidebar;
