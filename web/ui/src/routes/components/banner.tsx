import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import VariantsExample from './banner/examples/VariantsExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const BannerPage: React.FC = () => (
  <ComponentDemoPage
    title="Banner"
    description="Displays compact contextual notices for neutral information, warnings, and errors."
  >
    <DemoExample
      component={<VariantsExample />}
      path="./examples/VariantsExample.tsx"
      description="All supported banner variants with the default icons and color treatments."
      demoHeight="20rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/banner`)({
  component: BannerPage,
});
