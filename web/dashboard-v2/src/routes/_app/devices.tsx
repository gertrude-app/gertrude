import { createFileRoute } from '@tanstack/react-router';
import React from 'react';

const DevicesPage: React.FC = () => <div>Devices</div>;

export const Route = createFileRoute(`/_app/devices`)({
  component: DevicesPage,
});
