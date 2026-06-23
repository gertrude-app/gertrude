import { createFileRoute } from '@tanstack/react-router';
import type React from 'react';

const Home: React.FC = () => (
  <div className="p-8">
    <h1 className="text-4xl font-bold">Welcome to Gertrude UI</h1>
    <p className="mt-4 text-lg">
      Edit <code>src/routes/index.tsx</code> to get started.
    </p>
  </div>
);

export const Route = createFileRoute(`/`)({ component: Home });
