import Button from '@shared/Button';
import KeychainCard from '@shared/dashboard/KeychainCard';
import PageHeading from '@shared/dashboard/PageHeading';
import React from 'react';

const Keychains: React.FC = () => {
  // TEMP
  const fakeData: Array<{
    shared: boolean;
    name: string;
    description: string;
    keys: number;
  }> = [
    {
      shared: true,
      name: `HTC`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 232,
    },
    {
      shared: true,
      name: `Google Docs`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 7,
    },
    {
      shared: false,
      name: `Jason's blog`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 3,
    },
    {
      shared: true,
      name: `MSF Verified Safe Sites`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 433,
    },
    {
      shared: false,
      name: `John's stuff`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 674,
    },
    {
      shared: true,
      name: `Smith Family`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 112,
    },
    {
      shared: true,
      name: `Meyer Hatchery`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 14,
    },
    {
      shared: false,
      name: `Facebook`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 2390,
    },
    {
      shared: false,
      name: `Friends Library`,
      description: `Lorem ipsum, dolor sit amet consectetur adipisicing elit. Tempore laudantium velit assumenda nemo exercitationem.`,
      keys: 2,
    },
  ];

  return (
    <div className="px-0 sm:px-4">
      <PageHeading icon="key">Keychains</PageHeading>
      <p className="mt-4 text-sm text-gray-500">
        Keychains are clusters of related individual "keys" for selectively unlocking
        internet access. They can be organized however you like—per use, by application,
        for a specific school class, etc. Or, you can put all of your keys in one keychain
        if you prefer.
      </p>
      <div className="grid grid-cols-1 lg+:grid-cols-2 gap-10 lg+:gap-8 xl:gap-10 2xl:grid-cols-3 mt-10">
        {fakeData.map(({ shared, name, description, keys }) => (
          <KeychainCard
            shared={shared}
            name={name}
            keys={keys}
            description={description}
            editable
            className=""
          />
        ))}
      </div>
      <div className="mt-8 flex justify-end border-t pt-6">
        <Button type="button" onClick={() => {}} color="primary-violet">
          <i className="fa fa-plus mr-2" /> Create keychain
        </Button>
      </div>
    </div>
  );
};

export default Keychains;
