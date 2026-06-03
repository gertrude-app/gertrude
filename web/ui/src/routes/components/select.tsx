import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './select/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const SelectPage: React.FC = () => (
  <ComponentDemoPage
    title="Select"
    description="Chooses one string value from a fixed list, with small and medium sizes plus optional top or left labels, icons, and item descriptions."
  >
    <DemoExample
      component={<AssortmentExample />}
      path="./examples/AssortmentExample.tsx"
      description="Small, medium, disabled, top-labeled, left-labeled, and label/value selects with dropdown icons and descriptions."
      demoHeight="21rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/select`)({
  component: SelectPage,
});
