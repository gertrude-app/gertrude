import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import SizesExample from './loading-dots/examples/SizesExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const LoadingDotsPage: React.FC = () => (
  <ComponentDemoPage
    title="LoadingDots"
    description="Displays a compact three-dot loading indicator."
  >
    <DemoExample
      component={<SizesExample />}
      path="./examples/SizesExample.tsx"
      description="Small, medium, and large loading dots."
      demoHeight="14rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/loading-dots`)({
  component: LoadingDotsPage,
});
