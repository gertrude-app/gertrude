import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import BasicExample from './confirmation-dialog/examples/BasicExample';
import DestructiveExample from './confirmation-dialog/examples/DestructiveExample';

const ConfirmationDialogPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Confirmation Dialog"
      description="Asks users to confirm a choice using the responsive Modal primitive underneath."
    >
      <DemoExample
        component={<BasicExample />}
        path="./examples/BasicExample.tsx"
        description="A confirmation dialog with cancel and primary actions."
        demoHeight="20rem"
      />
      <DemoExample
        component={<DestructiveExample />}
        path="./examples/DestructiveExample.tsx"
        description="Destructive confirmations can use destructive action styling and loading states."
        demoHeight="20rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/confirmation-dialog')({
  component: ConfirmationDialogPage,
});
