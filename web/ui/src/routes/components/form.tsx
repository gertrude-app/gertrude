import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import SettingsExample from './form/examples/SettingsExample';

const FormPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Form"
      description="Arranges form controls as a vertical list of rows, with each row optionally providing a label and description around arbitrary children."
    >
      <DemoExample
        component={<SettingsExample />}
        path="./examples/SettingsExample.tsx"
        description="A dashboard-shaped settings form showing labels, descriptions, selects, inputs, and an action row in one vertical stack."
        demoHeight="32rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/form')({
  component: FormPage,
});
