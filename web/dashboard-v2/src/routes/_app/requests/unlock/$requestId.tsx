import { createFileRoute } from '@tanstack/react-router';
import type React from 'react';

const UnlockRequestRoute: React.FC = (): null => null;

export const Route = createFileRoute(`/_app/requests/unlock/$requestId`)({
  component: UnlockRequestRoute,
});
