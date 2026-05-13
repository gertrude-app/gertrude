import React from 'react';
import { createFileRoute } from '@tanstack/react-router';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';
import AssortmentExample from './input/examples/AssortmentExample';
import TypeVariantsExample from './input/examples/TypeVariantsExample';
import PrefixSuffixExample from './input/examples/PrefixSuffixExample';
import ButtonActionExample from './input/examples/ButtonActionExample';
import InlineButtonExample from './input/examples/InlineButtonExample';
import DisabledExample from './input/examples/DisabledExample';
import HelperAndErrorExample from './input/examples/HelperAndErrorExample';

const InputPage: React.FC = () => {
  return (
    <ComponentDemoPage
      title="Input"
      description="Collects text, email, password, and numeric values with optional labels, fixed prefix or suffix text, and inset actions."
    >
      <DemoExample
        component={<AssortmentExample />}
        path="./examples/AssortmentExample.tsx"
        description="A mixed set of common dashboard input shapes."
        demoHeight="18rem"
      />
      <DemoExample
        component={<ButtonActionExample />}
        path="./examples/ButtonActionExample.tsx"
        description="Inset action buttons for submitting, checking, copying, or applying the current value."
        demoHeight="18rem"
      />
      <DemoExample
        component={<InlineButtonExample />}
        path="./examples/InlineButtonExample.tsx"
        description="Inputs can sit inline with a separate button when the action should feel more explicit than an inset control."
        demoHeight="18rem"
      />
      <DemoExample
        component={<TypeVariantsExample />}
        path="./examples/TypeVariantsExample.tsx"
        description="The supported value types."
        demoHeight="17rem"
      />
      <DemoExample
        component={<PrefixSuffixExample />}
        path="./examples/PrefixSuffixExample.tsx"
        description="Fixed prefixes and suffixes for URLs, domains, durations, and quantities."
        demoHeight="17rem"
      />
      <DemoExample
        component={<HelperAndErrorExample />}
        path="./examples/HelperAndErrorExample.tsx"
        description="Helper text and errors provide field-level guidance and are wired to the input for assistive technology."
        demoHeight="18rem"
      />
      <DemoExample
        component={<DisabledExample />}
        path="./examples/DisabledExample.tsx"
        description="Disabled inputs mute the field and prevent both typing and inset button actions."
        demoHeight="17rem"
      />
    </ComponentDemoPage>
  );
};

export const Route = createFileRoute('/components/input')({
  component: InputPage,
});
