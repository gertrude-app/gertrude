import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './badge/examples/AssortmentExample';
import ColorVariantsExample from './badge/examples/ColorVariantsExample';
import SizeScaleExample from './badge/examples/SizeScaleExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const BadgePage: React.FC = () => (
  <ComponentDemoPage
    title="Badge"
    description="Displays short status, category, or count labels inline with surrounding content."
  >
    <DemoExample
      component={<AssortmentExample />}
      path="./examples/AssortmentExample.tsx"
      description="A quick mixed set of badges across colors, sizes, and optional Lucide icons."
      demoHeight="12rem"
    />
    <DemoExample
      component={<ColorVariantsExample />}
      path="./examples/ColorVariantsExample.tsx"
      description="The supported color variants, each shown with and without an icon."
      demoHeight="22rem"
    />
    <DemoExample
      component={<SizeScaleExample />}
      path="./examples/SizeScaleExample.tsx"
      description="Small, medium, and large badge sizes, each shown with and without an icon."
      demoHeight="15rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/badge`)({
  component: BadgePage,
});
