import React from 'react';
import { createFileRoute } from '@tanstack/react-router';

const BillingSettingsPage: React.FC = () => <div>billing</div>;

export const Route = createFileRoute('/_app/settings/billing')({
  component: BillingSettingsPage,
});
