import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const AppsPage: React.FC = () => <div>Apps</div>;

export const Route = createFileRoute(`/_app/apps`)({
  component: AppsPage,
});
