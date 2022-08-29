import KeyCreator from '@shared/dashboard/KeyCreator';
import PageHeading from '@shared/dashboard/PageHeading';
import React from 'react';

interface Props {}

const CreateKeyPage: React.FC<Props> = ({}) => {
  return (
    <div>
      <PageHeading icon="key">Create key</PageHeading>
      <div />
      <KeyCreator />
    </div>
  );
};

export default CreateKeyPage;
