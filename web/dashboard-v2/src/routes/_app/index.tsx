import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const DashboardPage: React.FC = () => <div>Dashboard</div>;

export const Route = createFileRoute('/_app/')({
  component: DashboardPage,
});
