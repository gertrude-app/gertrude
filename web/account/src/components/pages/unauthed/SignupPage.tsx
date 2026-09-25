import { Banner, Button, Input, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import RotatingTestimonials, {
  type Testimonial,
} from '#/components/unauthed/RotatingTestimonials';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

interface Props {
  email: string;
  setEmail: (email: string) => void;
  password: string;
  setPassword: (password: string) => void;
  testimonials: Testimonial[];
  onSubmit: (event: React.FormEvent) => void;
  submitting?: boolean;
  error?: string | null;
  sent?: boolean;
  resendSeconds?: number;
  onResend: () => void;
  onChangeEmail: () => void;
  securityCheck?: React.ReactNode;
  securityReady?: boolean;
}

const SignupPage: React.FC<Props> = ({
  email,
  setEmail,
  password,
  setPassword,
  testimonials,
  onSubmit,
  submitting = false,
  error,
  sent = false,
  resendSeconds = 0,
  onResend,
  onChangeEmail,
  securityCheck,
  securityReady = true,
}) => (
  <UnauthedPageLayout
    form={
      <UnauthedForm
        onSubmit={sent ? (event) => event.preventDefault() : onSubmit}
        inputs={[
          ...(sent
            ? [
                <VStack key="sent" gap={3} className="py-1" role="status">
                  <Text as="p" variant="bodyMuted" className="break-words">
                    We sent an email to
                    <span className="block break-all text-stone-900">{email}</span>
                  </Text>
                  <Text as="p" variant="bodyMuted">
                    Open it to finish signing up, or to get help logging in if you already
                    have an account. Check your spam folder if it doesn't arrive.
                  </Text>
                </VStack>,
              ]
            : [
                <Input
                  key="email"
                  type="email"
                  name="email"
                  value={email}
                  setValue={setEmail}
                  label="Email"
                  placeholder="you@example.com"
                  autoComplete="email"
                  required
                  disabled={submitting}
                />,
                <Input
                  key="password"
                  type="password"
                  name="password"
                  value={password}
                  setValue={setPassword}
                  label="Password"
                  placeholder="Choose a password"
                  autoComplete="new-password"
                  helperText="Use at least five characters."
                  required
                  disabled={submitting}
                />,
              ]),
          error && (
            <div key="error" role="alert">
              <Banner variant="error">{error}</Banner>
            </div>
          ),
          securityCheck && (
            <div key="security" className="self-center">
              {securityCheck}
            </div>
          ),
        ]}
        buttons={
          sent
            ? [
                <Button
                  key="resend"
                  type="button"
                  onClick={onResend}
                  loading={submitting}
                  disabled={submitting || !securityReady || resendSeconds > 0}
                >
                  {resendSeconds > 0
                    ? `Resend email in ${resendSeconds}s`
                    : `Resend email`}
                </Button>,
                <Button
                  key="change-email"
                  type="button"
                  variant="ghost"
                  onClick={onChangeEmail}
                  disabled={submitting}
                >
                  Use a different email
                </Button>,
              ]
            : [
                <Button
                  key="signup"
                  type="submit"
                  variant="primary"
                  icon={ArrowRightIcon}
                  iconPosition="right"
                  loading={submitting}
                  disabled={
                    !email.trim() || password.length < 5 || submitting || !securityReady
                  }
                >
                  Create account
                </Button>,
              ]
        }
        heading={sent ? `Check your email` : `Create your account`}
        subheading={
          sent
            ? `One last step to get started.`
            : `One account for all your Gertrude apps.`
        }
        disclaimer={
          !sent && (
            <>
              By signing up, you agree to our{` `}
              <a
                href="https://gertrude.app/legal/terms"
                target="_blank"
                rel="noreferrer"
                className="underline decoration-dotted underline-offset-2"
              >
                terms of service
              </a>
              .
            </>
          )
        }
        bottomLink={{ text: `Log in instead`, href: `/login` }}
        bottomLinkExplanation="Already have an account?"
      />
    }
    rightDisplay={
      <VStack align="center" className="h-full overflow-hidden pt-20 relative">
        <img src="/logo-wordmark.svg" alt="Gertrude" className="w-36 relative" />
        <Text as="h2" variant="display" className="mt-8 relative">
          Here's what parents are saying.
        </Text>
        <Text as="h3" variant="subheading" className="mt-1 relative mb-4">
          Just in case you'd be inclined to doubt us.
        </Text>
        <RotatingTestimonials testimonials={testimonials} />
      </VStack>
    }
  />
);

export default SignupPage;
