import { createFileRoute } from '@tanstack/react-router';
import LinkExpiredPage from '#/components/pages/unauthed/LinkExpiredPage';

export const Route = createFileRoute(`/(unauthed)/link-expired`)({
  component: LinkExpiredPage,
});
