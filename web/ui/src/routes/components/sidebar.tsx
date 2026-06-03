import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './sidebar/examples/BasicExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const SidebarPage: React.FC = () => (
  <ComponentDemoPage
    title="Sidebar"
    description="A simple sidebar component with support for sections and linked items."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="Basic usage of the sidebar component"
      demoHeight="42rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/sidebar`)({
  component: SidebarPage,
});
