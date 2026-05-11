import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import BasicExample from './examples/BasicExample';

const SidebarPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Sidebar"
      description="A simple sidebar component with support for sections and sub-items."
    >
      <DemoExample
        component={<BasicExample />}
        path="./examples/BasicExample.tsx"
        description="Basic usage of the sidebar component"
        demoHeight="42rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/fragments/sidebar/')({
  component: SidebarPage,
});
