import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './slide-over/examples/BasicExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const SlideOverPage: React.FC = () => (
  <ComponentDemoPage
    title="Slide Over"
    description="Displays custom panel content as a right-side sheet on desktop and a full-height bottom sheet on small screens."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="A basic slide over with fully custom children. Resize below the medium breakpoint to see the same content become a full-height mobile sheet."
      demoHeight="28rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/slide-over`)({
  component: SlideOverPage,
});
