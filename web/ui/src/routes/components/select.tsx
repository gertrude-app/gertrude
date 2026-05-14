import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './select/examples/AssortmentExample';

const SelectPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Select"
      description="Chooses one string value from a fixed list, with optional built-in labeling."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="Labeled, unlabeled, and disabled selects."
        demoHeight="17rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/select')({
  component: SelectPage,
});
