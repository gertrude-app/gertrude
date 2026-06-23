import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './radio-group/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const RadioGroupPage: React.FC = () => (
  <ComponentDemoPage
    title="Radio Group"
    description="Captures one choice from a short set of mutually exclusive options."
  >
    <DemoExample
      component={<AssortmentExample />}
      path="./examples/AssortmentExample.tsx"
      description="Vertical, horizontal, unlabeled, and disabled radio groups."
      demoHeight="22rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/radio-group`)({
  component: RadioGroupPage,
});
