import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './modal/examples/BasicExample';
import SizesExample from './modal/examples/SizesExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const ModalPage: React.FC = () => (
  <ComponentDemoPage
    title="Modal"
    description="Displays responsive overlay content as a centered dialog on larger screens and a Vaul drawer on smaller screens."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="A basic modal with title, description, body content, and footer actions. Resize below the medium breakpoint to see the drawer presentation."
      demoHeight="24rem"
    />
    <DemoExample
      component={<SizesExample />}
      path="./examples/SizesExample.tsx"
      description="Modal width can be tuned with small, medium, and large size variants while keeping the same mobile drawer behavior."
      demoHeight="24rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/modal`)({
  component: ModalPage,
});
