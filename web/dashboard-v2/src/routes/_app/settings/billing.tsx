import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const BillingSettingsPage: React.FC = () => <div>billing</div>;

export const Route = createFileRoute(`/_app/settings/billing`)({
  component: BillingSettingsPage,
});
