import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './textarea/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const TextareaPage: React.FC = () => (
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

export const Route = createFileRoute(`/components/textarea`)({
  component: TextareaPage,
});
