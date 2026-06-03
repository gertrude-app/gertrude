import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import AssortmentExample from './date-time-picker/examples/AssortmentExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const DateTimePickerPage: React.FC = () => (
  <ComponentDemoPage
    title="DateTimePicker"
    description="Selects a calendar date and time value with optional top or left labels, small or medium sizing, past/future bounds, and optional clearing."
  >
    <DemoExample
      component={<AssortmentExample />}
      path="./examples/AssortmentExample.tsx"
      description="Small, medium, top-labeled, left-labeled, unlabeled, past-only, future-only, and optional date/time pickers bound to independent Date state values."
      demoHeight="33rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/date-time-picker`)({
  component: DateTimePickerPage,
});
