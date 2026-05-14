import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './checkbox/examples/AssortmentExample';

const CheckboxPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Checkbox"
      description="Captures independent boolean choices for settings, filters, confirmations, and multi-select lists."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="Checked, unchecked, indeterminate, disabled, and label/description combinations."
        demoHeight="22rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/checkbox')({
  component: CheckboxPage,
});
