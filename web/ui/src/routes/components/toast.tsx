import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './toast/examples/BasicExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const ToastPage: React.FC = () => (
  <ComponentDemoPage
    title="Toast"
    description="Shows short messages from anywhere in the app with a global toast function."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="Call toast.success, toast.error, toast.info, or toast.async with the text from the input."
      demoHeight="18rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/toast`)({
  component: ToastPage,
});
