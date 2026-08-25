import { Outlet, createFileRoute } from '@tanstack/react-router';
import React from 'react';

const BillingRoute: React.FC = () => <Outlet />;

export const Route = createFileRoute(`/_app/settings/billing`)({
  component: BillingRoute,
});
