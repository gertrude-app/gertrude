import React from 'react';
import { Outlet, createFileRoute } from '@tanstack/react-router';

const PeopleLayout: React.FC = () => <Outlet />;

export const Route = createFileRoute('/_app/people')({
  component: PeopleLayout,
});
