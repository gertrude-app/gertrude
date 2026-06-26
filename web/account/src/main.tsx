import './styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from '@tanstack/react-router';
import React from 'react';
import ReactDOM from 'react-dom/client';
import { createRouter } from './router';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 3, refetchOnWindowFocus: false },
  },
});

const router = createRouter(queryClient);

const rootElement = document.getElementById(`app`);
if (rootElement && !rootElement.innerHTML) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <QueryClientProvider client={queryClient}>
        <RouterProvider router={router} />
      </QueryClientProvider>
    </React.StrictMode>,
  );
}
