import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const ActivityPage: React.FC = () => <div>Activity</div>;

export const Route = createFileRoute(`/_app/activity`)({
  component: ActivityPage,
});
