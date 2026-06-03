import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import BasicExample from './dropdown-menu/examples/BasicExample';
import NestedMenuExample from './dropdown-menu/examples/NestedMenuExample';
import SearchableExample from './dropdown-menu/examples/SearchableExample';
import SelectedItemsExample from './dropdown-menu/examples/SelectedItemsExample';
import ComponentDemoPage from '#/components/demo/ComponentDemoPage';
import DemoExample from '#/components/demo/DemoExample';

const DropdownMenuPage: React.FC = () => (
  <ComponentDemoPage
    title="Dropdown Menu"
    description="Displays a menu of actions or choices from a trigger, with optional search, icons, descriptions, selected state, and nested sub-menus."
  >
    <DemoExample
      component={<BasicExample />}
      path="./examples/BasicExample.tsx"
      description="A simple action menu with optional item descriptions."
      demoHeight="22rem"
    />
    <DemoExample
      component={<SelectedItemsExample />}
      path="./examples/SelectedItemsExample.tsx"
      description="Selectable menus can mark the current choice, with and without icons."
      demoHeight="18rem"
    />
    <DemoExample
      component={<NestedMenuExample />}
      path="./examples/NestedMenuExample.tsx"
      description="Items can include children for sub-menus, and nested choices can also show selected state."
      demoHeight="18rem"
    />
    <DemoExample
      component={<SearchableExample />}
      path="./examples/SearchableExample.tsx"
      description="Searchable menus support longer choice lists, including selected items and mixed icon density."
      demoHeight="19rem"
    />
  </ComponentDemoPage>
);

export const Route = createFileRoute(`/components/dropdown-menu`)({
  component: DropdownMenuPage,
});
