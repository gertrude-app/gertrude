import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const SignoutPage: React.FC = () => <div>Sign out</div>;

export const Route = createFileRoute(`/_app/signout`)({
  component: SignoutPage,
});
