import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './tooltip/examples/BasicExample';
import PlacementExample from './tooltip/examples/PlacementExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const TooltipPage: React.FC = () => (
  <ComponentDemoPage
    title="Tooltip"
    description="Shows a short visual hint when an element is hovered or focused."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="Tooltips can wrap icon-only controls, buttons, and other focusable elements."
      demoHeight="16rem"
    />
    <DemoExample
      component={<PlacementExample />}
      path="./examples/PlacementExample.tsx"
      description="Choose the preferred side while Base UI handles viewport collision behavior."
      demoHeight="22rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/tooltip`)({
  component: TooltipPage,
});
