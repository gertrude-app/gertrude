import React from 'react';
import { createFileRoute } from '@tanstack/react-router';

// TODO: make button component

const ButtonPage: React.FC = () => {
  return <div>Hello "/atoms/button"!</div>;
};

export const Route = createFileRoute('/atoms/button')({
  component: ButtonPage,
});
