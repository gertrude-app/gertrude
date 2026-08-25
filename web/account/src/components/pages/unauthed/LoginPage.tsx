import { Button, HStack, Input, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import AppAd from '#/components/unauthed/AppAd';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

interface Props {
  email: string;
  setEmail: (email: string) => void;
  password: string;
  setPassword: (password: string) => void;
  submitting?: boolean;
  sendingLink?: boolean;
  onSubmit: (event: React.FormEvent) => void;
  onMagicLink: () => void;
}

const LoginPage: React.FC<Props> = ({
  email,
  setEmail,
  password,
  setPassword,
  submitting = false,
  sendingLink = false,
  onSubmit,
  onMagicLink,
}) => (
  <UnauthedPageLayout
    form={
      <UnauthedForm
        onSubmit={onSubmit}
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
            onClick={onMagicLink}
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
          <HStack
            key="reset-password"
            as="a"
            href="/reset-password"
            className="self-end text-xs font-medium text-stone-500 transition-colors hover:text-stone-700"
          >
            Forgot password?
          </HStack>,
        ]}
        heading="Log in"
        subheading="Sign in with your password or a magic link."
        bottomLink={{
          text: `Signup instead`,
          href: `/signup`,
        }}
        bottomLinkExplanation="Don't have an account?"
      />
    }
    rightDisplay={<LoginAppsDisplay />}
  />
);

export default LoginPage;

const LoginAppsDisplay: React.FC = () => (
  <VStack align="center" className="h-full pt-20 relative overflow-scroll bg-stone-50">
    <img src="/logo-wordmark.svg" alt="Gertrude" className="w-36 relative" />
    <Text as="h2" variant="display" className="mt-8 relative">
      Have you tried all our apps?
    </Text>
    <Text as="h3" variant="subheading" className="mt-1 relative">
      We're biased, but we think they're pretty great.
    </Text>
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
  </VStack>
);
