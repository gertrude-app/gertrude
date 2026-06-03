import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './page-heading/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const PageHeadingPage: React.FC = () => (
  <ComponentDemoPage
    title="Page Heading"
    description="Introduces a page with an optional breadcrumb trail and compact action buttons."
  >
    <DemoExample
      component={<AssortmentExample />}
      path="./examples/AssortmentExample.tsx"
      description="Title-only, breadcrumb, and action-button configurations shown together."
      demoHeight="28rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/page-heading`)({
  component: PageHeadingPage,
});
