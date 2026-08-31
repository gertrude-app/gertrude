import { toast } from '@gertrude/ui';
import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import { ChooseNewPasswordPage } from '#/components/pages/unauthed/PasswordResetPages';
import { isAuthed } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const ChooseNewPasswordRoute: React.FC = () => {
  const { token } = Route.useParams();
  const [password, setPassword] = React.useState(``);
  const [submitting, setSubmitting] = React.useState(false);
  const [succeeded, setSucceeded] = React.useState(false);
  const [invalidToken, setInvalidToken] = React.useState(false);

  const submit = async (event: React.FormEvent): Promise<void> => {
    event.preventDefault();
    if (password.length < 5 || submitting) {
      return;
    }

    setSubmitting(true);
    const result = await liveClient.accountResetPassword({ token, password });
    setSubmitting(false);
    result.with({
      success: (output) => {
        if (output.success) {
          setSucceeded(true);
        } else {
          setInvalidToken(true);
        }
      },
      error: (error) =>
        toast.error(error.userMessage ?? `Couldn't update your password.`),
    });
  };

  return (
    <ChooseNewPasswordPage
      password={password}
      setPassword={setPassword}
      submitting={submitting}
      succeeded={succeeded}
      invalidToken={invalidToken}
      backLink={
        isAuthed()
          ? { text: `Back to settings`, href: `/settings` }
          : { text: `Back to login`, href: `/login` }
      }
      onSubmit={(event) => void submit(event)}
    />
  );
};

export const Route = createFileRoute(`/(unauthed)/reset-password/$token`)({
  component: ChooseNewPasswordRoute,
});
