import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const KeychainsPage: React.FC = () => <div>Keychains</div>;

export const Route = createFileRoute('/_app/keychains')({
  component: KeychainsPage,
});
