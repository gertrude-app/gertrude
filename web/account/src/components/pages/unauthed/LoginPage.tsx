import { Banner, Button, HStack, Input, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon, LaptopIcon, SmartphoneIcon, TabletIcon } from 'lucide-react';
import React from 'react';
import type { AppAdTag } from '#/components/unauthed/AppAd';
import type { ConnectingDevice } from '#/lib/authRedirect';
import { type SetupApp, setupApps } from '#/components/onboarding/setupApps';
import AppAd from '#/components/unauthed/AppAd';
import ConnectingSubheading from '#/components/unauthed/ConnectingSubheading';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';
import { gertrudeApps } from '#/lib/gertrudeApps';

interface Props {
  email: string;
  setEmail: (email: string) => void;
  password: string;
  setPassword: (password: string) => void;
  error?: string | null;
  submitting?: boolean;
  sendingLink?: boolean;
  onSubmit: (event: React.FormEvent) => void;
  onMagicLink: () => void;
  signupHref?: string;
  connecting?: ConnectingDevice;
}

const LoginPage: React.FC<Props> = ({
  email,
  setEmail,
  password,
  setPassword,
  error,
  submitting = false,
  sendingLink = false,
  onSubmit,
  onMagicLink,
  signupHref = `/signup`,
  connecting,
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
            autoComplete="email"
          />,
          <Input
            key="password"
            type="password"
            value={password}
            setValue={setPassword}
            label="Password"
            placeholder="••••••••••"
            autoComplete="current-password"
          />,
          ...(error
            ? [
                <div key="error" role="alert">
                  <Banner variant="error">
                    {error === `Incorrect email or password` ? (
                      <>
                        <strong className="block">Email or password didn't match</strong>
                        <span className="mt-1 block text-sm">
                          Check your details, or send a magic link instead.
                        </span>
                      </>
                    ) : (
                      error
                    )}
                  </Banner>
                </div>,
              ]
            : []),
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
            loading={submitting}
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
        subheading={
          connecting ? (
            <ConnectingSubheading device={connecting} />
          ) : (
            `Sign in with your password or a magic link.`
          )
        }
        bottomLink={{
          text: `Signup instead`,
          href: signupHref,
        }}
        bottomLinkExplanation="Don't have an account?"
        sideWordmark
      />
    }
    rightDisplay={<LoginAppsDisplay />}
  />
);

export default LoginPage;

const platformTags: Record<(typeof setupApps)[number][`platforms`][number], AppAdTag> = {
  mac: { text: `macOS`, icon: LaptopIcon },
  iphone: { text: `iOS`, icon: SmartphoneIcon },
  ipad: { text: `iPadOS`, icon: TabletIcon },
};

const subheadings: Record<SetupApp, string> = {
  mac: `Allow only approved websites, with screenshots, keystroke monitoring, app blocking, and downtime.`,
  blocker: `Close the gaps Screen Time leaves on iPhone and iPad.`,
  music: `Music from an approved library, without open-ended browsing.`,
  podcasts: `Approved shows, with a PIN required to add new podcasts.`,
};

const appAds = setupApps.map((app) => ({
  app: app.id,
  subheading: subheadings[app.id],
  tags: [
    ...app.platforms.map((platform) => platformTags[platform]),
    ...(app.id === `mac` ? [{ text: `21-day free trial` }] : []),
  ],
}));

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
      {appAds.map((ad) => (
        <AppAd
          key={ad.app}
          visual={`/gertrude-app-visuals/${ad.app}.webp`}
          heading={gertrudeApps[ad.app].name}
          subheading={ad.subheading}
          tags={ad.tags}
        />
      ))}
    </div>
  </VStack>
);
