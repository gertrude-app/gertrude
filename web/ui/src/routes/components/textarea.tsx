import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './textarea/examples/AssortmentExample';

const TextareaPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Textarea"
      description="Collects longer freeform text for notes, explanations, and support messages."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="Standard, helper, error, disabled, and resize variants."
        demoHeight="28rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/textarea')({
  component: TextareaPage,
});
