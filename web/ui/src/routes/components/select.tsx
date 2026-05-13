import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './select/examples/AssortmentExample';
import ControlledValuesExample from './select/examples/ControlledValuesExample';
import LabelsExample from './select/examples/LabelsExample';

const SelectPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Select"
      description="Chooses one string value from a fixed list, with optional built-in labeling."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="A quick set of dashboard selects with different option counts and selected values."
        demoHeight="17rem"
      />
      <DemoExample
        component={<LabelsExample />}
        path="./examples/LabelsExample.tsx"
        description="Selects can render with their own label, or stay unlabeled when a surrounding FormRow supplies the copy."
        demoHeight="17rem"
      />
      <DemoExample
        component={<ControlledValuesExample />}
        path="./examples/ControlledValuesExample.tsx"
        description="Each select is controlled with selected and setSelected, so outside UI can respond to the current choice."
        demoHeight="18rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/select')({
  component: SelectPage,
});
