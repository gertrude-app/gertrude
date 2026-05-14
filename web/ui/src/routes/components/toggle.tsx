import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import StatesExample from './toggle/examples/StatesExample';

const TogglePage: React.FC = () => {
  return (
    <ComponentDemoPage title="Toggle" description="Switches a boolean setting on or off.">
      <DemoExample
        component={<StatesExample />}
        path="./examples/StatesExample.tsx"
        description="On, off, on disabled, and off disabled states."
        demoHeight="14rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/toggle')({
  component: TogglePage,
});
