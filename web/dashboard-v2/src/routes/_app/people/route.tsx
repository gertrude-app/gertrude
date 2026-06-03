import { Outlet, createFileRoute } from '@tanstack/react-router';
import React from 'react';

const PeopleLayout: React.FC = () => <Outlet />;

export const Route = createFileRoute(`/_app/people`)({
  component: PeopleLayout,
});
