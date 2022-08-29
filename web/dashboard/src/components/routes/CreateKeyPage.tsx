import KeyCreator from '@shared/dashboard/KeyCreator';
import PageHeading from '@shared/dashboard/PageHeading';
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
