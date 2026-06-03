import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import StatesExample from './toggle/examples/StatesExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const TogglePage: React.FC = () => (
  <ComponentDemoPage title="Toggle" description="Switches a boolean setting on or off.">
    <DemoExample
      component={<StatesExample />}
      path="./examples/StatesExample.tsx"
      description="On, off, on disabled, and off disabled states."
      demoHeight="14rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/toggle`)({
  component: TogglePage,
});
