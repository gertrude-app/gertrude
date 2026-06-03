import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './checkbox/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const CheckboxPage: React.FC = () => (
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

export const Route = createFileRoute(`/components/checkbox`)({
  component: CheckboxPage,
});
