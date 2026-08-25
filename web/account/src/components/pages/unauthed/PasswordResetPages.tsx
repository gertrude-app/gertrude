import { Banner, Button, Input } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

interface BackLink {
  text: string;
  href: string;
}

interface RequestProps {
  email: string;
  setEmail: (email: string) => void;
  submitting: boolean;
  sent: boolean;
  backLink: BackLink;
  onSubmit: (event: React.FormEvent) => void;
}

export const RequestPasswordResetPage: React.FC<RequestProps> = ({
  email,
  setEmail,
  submitting,
  sent,
  backLink,
  onSubmit,
}) => (
  <UnauthedPageLayout
    form={
      sent ? (
        <UnauthedForm
          inputs={[
            <Banner key="sent">
              If a Gertrude account uses <strong>{email}</strong>, a password-reset link
              is on its way.
            </Banner>,
          ]}
          buttons={[
            <Button key="back" type="link" href={backLink.href} variant="primary">
              {backLink.text}
            </Button>,
          ]}
          heading="Check your email"
          subheading="The reset link can only be used once and expires automatically."
        />
      ) : (
        <UnauthedForm
          onSubmit={onSubmit}
          inputs={[
            <Input
              key="email"
              type="email"
              value={email}
              setValue={setEmail}
              label="Email"
              placeholder="parent@example.com"
              autoComplete="email"
              required
            />,
          ]}
          buttons={[
            <Button
              key="send"
              type="submit"
              variant="primary"
              icon={ArrowRightIcon}
              iconPosition="right"
              loading={submitting}
              disabled={!email || submitting}
            >
              Send reset link
            </Button>,
          ]}
          heading="Reset your password"
          subheading="Enter your account email and we'll send a one-time reset link."
          bottomLink={backLink}
        />
      )
    }
  />
);

interface ChooseProps {
  password: string;
  setPassword: (password: string) => void;
  submitting: boolean;
  succeeded: boolean;
  invalidToken: boolean;
  backLink: BackLink;
  onSubmit: (event: React.FormEvent) => void;
}

export const ChooseNewPasswordPage: React.FC<ChooseProps> = ({
  password,
  setPassword,
  submitting,
  succeeded,
  invalidToken,
  backLink,
  onSubmit,
}) => (
  <UnauthedPageLayout
    form={
      succeeded ? (
        <UnauthedForm
          inputs={[
            <Banner key="success">
              Your password has been changed. You can now use it to log in to Gertrude.
            </Banner>,
          ]}
          buttons={[
            <Button key="continue" type="link" href="/people" variant="primary">
              Continue to Gertrude
            </Button>,
          ]}
          heading="Password updated"
          subheading="Your new password is ready to use."
        />
      ) : (
        <UnauthedForm
          onSubmit={onSubmit}
          inputs={[
            ...(invalidToken
              ? [
                  <Banner key="invalid" variant="error">
                    This reset link is invalid or expired. Request a new link to try
                    again.
                  </Banner>,
                ]
              : []),
            <Input
              key="password"
              type="password"
              value={password}
              setValue={setPassword}
              label="New password"
              placeholder="••••••••••"
              autoComplete="new-password"
              required
              disabled={invalidToken}
              helperText="Use at least five characters."
            />,
          ]}
          buttons={
            invalidToken
              ? [
                  <Button
                    key="request"
                    type="link"
                    href="/reset-password"
                    variant="primary"
                  >
                    Request a new link
                  </Button>,
                ]
              : [
                  <Button
                    key="save"
                    type="submit"
                    variant="primary"
                    icon={ArrowRightIcon}
                    iconPosition="right"
                    loading={submitting}
                    disabled={password.length < 5 || submitting}
                  >
                    Save new password
                  </Button>,
                ]
          }
          heading="Choose a new password"
          subheading="Enter the password you'll use the next time you log in."
          bottomLink={backLink}
        />
      )
    }
  />
);
