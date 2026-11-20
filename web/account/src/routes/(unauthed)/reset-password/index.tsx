import { toast } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import { RequestPasswordResetPage } from '#/components/pages/unauthed/PasswordResetPages';
import { isAuthed } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const RequestPasswordResetRoute: React.FC = () => {
  const { email: initialEmail } = Route.useSearch();
  const [email, setEmail] = React.useState(initialEmail ?? ``);
  const [submitting, setSubmitting] = React.useState(false);
  const [sent, setSent] = React.useState(false);

  const submit = async (event: React.FormEvent): Promise<void> => {
    event.preventDefault();
    if (!email || submitting) {
      return;
    }

    setSubmitting(true);
    const result = await liveClient.accountSendPasswordResetEmail({ email });
    setSubmitting(false);
    result.with({
      success: () => setSent(true),
      error: (error) =>
        toast.error(error.userMessage ?? `Couldn't send the password-reset email.`),
    });
  };

  return (
    <RequestPasswordResetPage
      email={email}
      setEmail={setEmail}
      submitting={submitting}
      sent={sent}
      backLink={
        isAuthed()
          ? { text: `Back to settings`, href: `/settings` }
          : { text: `Back to login`, href: `/login` }
      }
      onSubmit={(event) => void submit(event)}
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/reset-password/`)({
  validateSearch: (search): { email?: string } =>
    typeof search[`email`] === `string` && search[`email`].includes(`@`)
      ? { email: search[`email`].slice(0, 254) }
      : {},
  component: RequestPasswordResetRoute,
});
