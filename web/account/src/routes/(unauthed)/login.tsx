import { Badge, Button, Input, toast } from '@gertrude/ui';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import { ArrowRightIcon } from 'lucide-react';
import React, { useState } from 'react';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';
import { isAuthed, setAuth } from '#/pairql/auth';
import { liveClient } from '#/pairql/client';

const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState(``);
  const [password, setPassword] = useState(``);
  const [submitting, setSubmitting] = useState(false);
  const [sendingLink, setSendingLink] = useState(false);

  async function handleSubmit(event: React.FormEvent): Promise<void> {
    event.preventDefault();
    if (!email || !password || submitting) return;
    setSubmitting(true);
    const result = await liveClient.accountLogin({ email, password });
    setSubmitting(false);
    result.with({
      success: ({ accountId, token }) => {
        setAuth(accountId, token);
        void navigate({ to: `/people` });
      },
      error: (err) => {
        toast.error(err.userMessage ?? `Login failed — check your email and password.`);
      },
    });
  }

  async function handleMagicLink(): Promise<void> {
    if (!email || sendingLink) return;
    setSendingLink(true);
    const result = await liveClient.accountRequestMagicLink({ email });
    setSendingLink(false);
    result.with({
      success: () => toast.success(`Check your email for a sign-in link.`),
      error: (err) => toast.error(err.userMessage ?? `Couldn't send the magic link.`),
    });
  }

  return (
    <UnauthedPageLayout
      form={
        <UnauthedForm
          onSubmit={handleSubmit}
          inputs={[
            <Input
              key="email"
              type="email"
              value={email}
              setValue={setEmail}
              label="Email"
              placeholder="john@doe.com"
            />,
            <Input
              key="password"
              type="password"
              value={password}
              setValue={setPassword}
              label="Password"
              placeholder="••••••••••"
            />,
          ]}
          buttons={[
            <Button
              key="magic-link"
              type="button"
              onClick={handleMagicLink}
              disabled={!email || sendingLink}
            >
              Send magic link
            </Button>,
            <Button
              key="login"
              type="submit"
              variant="primary"
              icon={ArrowRightIcon}
              iconPosition="right"
              disabled={!email || !password || submitting}
            >
              Login
            </Button>,
          ]}
          heading="Log in"
          subheading="Sign in with your password or a magic link."
        />
      }
      rightDisplay={
        <div className="flex h-full flex-col items-center pt-20 relative overflow-scroll bg-stone-50">
          <img src="/logo-wordmark.svg" alt="Gertrude" className="w-36 relative" />
          <h2 className="text-3xl font-medium text-stone-900 mt-8 relative">
            Have you tried all our apps?
          </h2>
          <h3 className="text-lg text-stone-600 mt-1 relative">
            We're biased, but we think they're pretty great.
          </h3>
          <div className="grid grid-cols-2 gap-6 px-12 py-12">
            <AppAd
              screenshot="/mac-app-screenshot.png"
              appIcon="/gertrude-blocker-app-icon.webp"
              heading="Gertrude for macOS"
              subheading="Internet whitelisting, screenshot and keystroke monitoring, app blocking, downtime, and more"
              badges={[`macOS`, `30-day free trial`]}
            />
            <AppAd
              screenshot="/mac-app-screenshot.png"
              appIcon="/gertrude-blocker-app-icon.webp"
              heading="Gertrude Blocker"
              subheading="Filling in the gaps that Apple's ScreenTime leaves behind, making your iPhones and iPads truly safe"
              badges={[`iOS`, `iPadOS`]}
            />
            <AppAd
              screenshot="/mac-app-screenshot.png"
              appIcon="/gertrude-am-app-icon.webp"
              heading="Gertrude AM"
              subheading="Parent-curated & pin-protected podcasts"
              badges={[`iOS`, `iPadOS`]}
            />
          </div>
        </div>
      }
    />
  );
};

interface AppAdProps {
  screenshot: string;
  appIcon: string;
  heading: string;
  subheading: string;
  badges: string[];
}

const AppAd: React.FC<AppAdProps> = ({
  screenshot,
  appIcon,
  heading,
  subheading,
  badges,
}) => (
  <div className="flex flex-col rounded-3xl border border-stone-200 shadow-md shadow-stone-300/20 bg-white">
    <div className="bg-stone-50 h-50 flex justify-center items-center m-3 relative rounded-xl">
      <img
        src={screenshot}
        alt=""
        aria-hidden="true"
        className="w-full h-full object-cover rounded-xl absolute left-0 top-0 scale-100 blur-lg opacity-70"
      />
      <img
        src={screenshot}
        alt={`${heading} screenshot`}
        className="w-full h-full object-cover border border-white rounded-xl relative"
      />
    </div>
    <div className="flex justify-center items-center h-0">
      <img
        src={appIcon}
        alt={`${heading} icon`}
        className="w-20 h-20 rounded-[22px] shadow-md shadow-stone-300/30 -translate-y-4 border border-stone-200"
      />
    </div>
    <div className="pt-10 px-8 pb-8 flex flex-col items-center">
      <div className="flex justify-center gap-2 flex-wrap">
        {badges.map((b) => (
          <Badge key={b} color="neutral" size="small">
            {b}
          </Badge>
        ))}
      </div>
      <h3 className="text-lg text-stone-900 font-semibold text-center mt-2">{heading}</h3>
      <h4 className="text-sm text-stone-700 text-center">{subheading}</h4>
    </div>
  </div>
);

export const Route = createFileRoute(`/(unauthed)/login`)({
  beforeLoad: () => {
    if (isAuthed()) {
      throw redirect({ to: `/people` });
    }
  },
  component: LoginPage,
});
