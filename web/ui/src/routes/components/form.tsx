import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import SettingsExample from './form/examples/SettingsExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const FormPage: React.FC = () => (
  <ComponentDemoPage
    title="Form"
    description="Arranges form controls as a vertical list of rows, with each row optionally providing a label and description around arbitrary children."
  >
    <DemoExample
      component={<SettingsExample />}
      path="./examples/SettingsExample.tsx"
      description="A dashboard-shaped settings form showing labels, descriptions, selects, inputs, toggles, and an action row in one vertical stack."
      demoHeight="38rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/form`)({
  component: FormPage,
});
