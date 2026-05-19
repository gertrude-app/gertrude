import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const SettingsPage: React.FC = () => <div>Settings</div>;

export const Route = createFileRoute('/_app/settings')({
  component: SettingsPage,
});
