import './styles.css';
import { QueryClientProvider } from '@tanstack/react-query';
import { RouterProvider } from '@tanstack/react-router';
import React from 'react';
import ReactDOM from 'react-dom/client';
import { authRedirectForPath } from './lib/authRedirect';
import { clearAuth } from './pairql/auth';
import { createAccountQueryClient } from './pairql/queryClient';
import { createRouter } from './router';

const queryClient = createAccountQueryClient(handleLoggedOut);
const router = createRouter(queryClient);

function handleLoggedOut(): void {
  const loginRedirect = authRedirectForPath(router.state.location.href);
  clearAuth();
  queryClient.clear();
  void router.navigate({
    to: `/login`,
    search: { redirect: loginRedirect },
    replace: true,
  });
}

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
