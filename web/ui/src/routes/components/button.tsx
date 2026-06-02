import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './button/examples/AssortmentExample';
import VariantStatesExample from './button/examples/VariantStatesExample';
import SizeScaleExample from './button/examples/SizeScaleExample';
import LoadingTransitionExample from './button/examples/LoadingTransitionExample';
import SplitActionExample from './button/examples/SplitActionExample';

const ButtonPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Button"
      description="Displays a button or a component that looks like a button."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="A quick mixed set of buttons across variants, sizes, icons, links, and loading states."
        demoHeight="13rem"
      />
      <DemoExample
        component={<VariantStatesExample />}
        path="./examples/VariantStatesExample.tsx"
        description="Each color variant shown as plain text, icon left, icon right, and loading."
        demoHeight="18rem"
      />
      <DemoExample
        component={<SizeScaleExample />}
        path="./examples/SizeScaleExample.tsx"
        description="Small, medium, and large sizes with icons and loading states."
        demoHeight="15rem"
      />
      <DemoExample
        component={<SplitActionExample />}
        path="./examples/SplitActionExample.tsx"
        description="Split action buttons keep a primary default action on the left and a dropdown of alternate actions on the right."
        demoHeight="21rem"
      />
      <DemoExample
        component={<LoadingTransitionExample />}
        path="./examples/LoadingTransitionExample.tsx"
        description="Toggle loading to check the spinner transition across icon positions and button styles."
        demoHeight="24rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/button')({
  component: ButtonPage,
});
