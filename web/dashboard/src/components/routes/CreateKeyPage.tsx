import KeyCreator from '@dashboard/Keychains/Keys/KeyCreator';
import PageHeading from '@dashboard/PageHeading';
import React from 'react';

const CreateKeyPage: React.FC = () => {
  return (
    <div>
      <PageHeading icon="key">Create key</PageHeading>
      <div />
      <KeyCreator mode="create" />
    </div>
  );
};

export default CreateKeyPage;
