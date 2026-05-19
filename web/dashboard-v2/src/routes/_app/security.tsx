import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const SecurityPage: React.FC = () => <div>Security</div>;

export const Route = createFileRoute('/_app/security')({
  component: SecurityPage,
});
