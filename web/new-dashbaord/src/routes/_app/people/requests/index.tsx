import { createFileRoute, redirect } from '@tanstack/react-router';

export const Route = createFileRoute('/_app/people/requests/')({
  beforeLoad: () => {
    throw redirect({ to: '/people/requests/unlock' });
  },
});
