import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const BasicSettingsPage: React.FC = () => <div>Basic</div>;

export const Route = createFileRoute(`/_app/people/$personId/`)({
  component: BasicSettingsPage,
});
