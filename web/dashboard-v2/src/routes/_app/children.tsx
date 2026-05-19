import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const ChildrenPage: React.FC = () => <div>Children</div>;

export const Route = createFileRoute('/_app/children')({
  component: ChildrenPage,
});
