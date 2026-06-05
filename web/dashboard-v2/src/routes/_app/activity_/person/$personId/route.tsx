import { Outlet, createFileRoute } from '@tanstack/react-router';
import React from 'react';

const ActivityPersonLayout: React.FC = () => <Outlet />;

export const Route = createFileRoute(`/_app/activity_/person/$personId`)({
  component: ActivityPersonLayout,
});
