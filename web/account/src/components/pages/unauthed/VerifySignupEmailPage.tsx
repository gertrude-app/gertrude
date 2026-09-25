import { Banner, Button, LoadingDots, Text, VStack } from '@gertrude/ui';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

export type VerificationState =
  | { status: `verifying` }
  | { status: `alreadyVerified` }
  | { status: `error`; message: string; retryable: boolean };

interface Props {
  state: VerificationState;
  onRetry: () => void;
}

const VerifySignupEmailPage: React.FC<Props> = ({ state, onRetry }) => (
  <UnauthedPageLayout
    form={
      <UnauthedForm
        heading={
          state.status === `verifying`
            ? `Verifying your email`
            : state.status === `alreadyVerified`
              ? `Email already verified`
              : `Couldn't verify your email`
        }
        subheading={
          state.status === `verifying`
            ? `We'll log you in as soon as it's confirmed.`
            : state.status === `alreadyVerified`
              ? `You're all set. Log in to continue.`
              : `Let's get you back on track.`
        }
        inputs={[
          state.status === `verifying` ? (
            <VStack key="verifying" align="center" gap={3} className="py-5" role="status">
              <LoadingDots />
              <Text as="p" variant="bodyMuted">
                Confirming your email address…
              </Text>
            </VStack>
          ) : state.status === `alreadyVerified` ? (
            <VStack key="verified" align="center" className="py-4">
              <div className="rounded-full bg-violet-100 p-3 text-violet-600">
                <CheckIcon className="size-7" aria-hidden="true" />
              </div>
            </VStack>
          ) : (
            <div key="error" role="alert">
              <Banner variant="error">{state.message}</Banner>
            </div>
          ),
        ]}
        buttons={
          state.status === `verifying`
            ? []
            : state.status === `alreadyVerified`
              ? [
                  <Button key="login" type="link" href="/login" variant="primary">
                    Log in
                  </Button>,
                ]
              : [
                  state.retryable ? (
                    <Button key="retry" type="button" variant="primary" onClick={onRetry}>
                      Try again
                    </Button>
                  ) : (
                    <Button key="signup" type="link" href="/signup" variant="primary">
                      Back to signup
                    </Button>
                  ),
                  <Button key="login" type="link" href="/login" variant="ghost">
                    Back to login
                  </Button>,
                ]
        }
      />
    }
  />
);

export default VerifySignupEmailPage;
