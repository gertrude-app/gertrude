import { Banner, Button } from '@gertrude/ui';
import { ArrowRightIcon, LaptopIcon } from 'lucide-react';
import React from 'react';
import { burstConfetti } from './burstConfetti';
import DeviceArtwork from '#/components/people/DeviceArtwork';

type Device = {
  type: `iPhone` | `iPad`;
  modelName: string;
  modelIdentifier: string;
};

type Props = {
  device: Device;
  personName: string;
  onPrimary: () => void;
  onSecondary?: () => void;
} & (
  | { flow: `blockerConnect` }
  | {
      flow: `podcasts`;
      access: `active` | `trial` | `ending` | `lapsed`;
      accessEndsAt?: string;
    }
  | { flow: `music`; access: `active` | `trialReady` | `trial` | `unavailable` }
  | { flow: `blockerSupervise`; nextStep: `plan` | `computer` }
);

const ConnectIosAppResultPage: React.FC<Props> = (props) => {
  const { device, personName } = props;
  const appName =
    props.flow === `podcasts`
      ? `Gertrude Podcasts`
      : props.flow === `music`
        ? `Gertrude Music`
        : `Gertrude Blocker`;
  const icon =
    props.flow === `podcasts`
      ? `/gertrude-app-icons/podcasts.webp`
      : props.flow === `music`
        ? `/gertrude-app-icons/music.webp`
        : `/gertrude-app-icons/blocker.webp`;
  const needsPlan =
    (props.flow === `podcasts` && props.access === `lapsed`) ||
    (props.flow === `music` && props.access === `unavailable`);
  const supervision = props.flow === `blockerSupervise`;
  const heading = supervision
    ? `Device assigned to ${personName}`
    : needsPlan
      ? `Connected, but access needs attention`
      : `${appName} connected`;
  const primaryLabel = supervision
    ? props.nextStep === `plan`
      ? `Review your plan`
      : `Continue setup`
    : needsPlan
      ? `Manage your plan`
      : `${device.type} settings`;

  return (
    <div className="flex min-h-screen items-center justify-center bg-stone-50 xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat]">
      <main className="flex min-h-screen w-full flex-col bg-white shadow-stone-500/20 xs:my-8 xs:min-h-0 xs:max-w-[420px] xs:overflow-hidden xs:rounded-2xl xs:border xs:border-stone-200 xs:shadow-2xl">
        <div className="relative flex flex-col items-center px-5 pb-5 pt-8 text-center">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_center,rgba(196,180,255,0.16)_0%,transparent_75%),url(/bg.svg)] [background-position:center,center,center] [background-size:1440px_1440px,cover,cover] [mask-image:radial-gradient(ellipse_50%_50%_at_center,black_0%,transparent_100%)]"
          />
          <div className="relative h-16 w-40" aria-hidden="true">
            <div className="pairing-result-app absolute left-[26px] top-3 h-10 w-10">
              <img
                src={icon}
                alt=""
                className="pairing-result-app-icon h-10 w-10 rounded-xl shadow-sm"
              />
            </div>
            <div className="pairing-result-device absolute left-[98px] top-3 flex w-12 justify-center">
              <div
                className="pairing-result-device-artwork"
                onAnimationEnd={burstConfetti}
              >
                <DeviceArtwork
                  device={{
                    type: device.type === `iPad` ? `ipad` : `iphone`,
                    modelIdentifier: device.modelIdentifier,
                  }}
                  size="pairing"
                />
              </div>
            </div>
          </div>
          <h1 className="relative mt-5 text-lg font-semibold text-stone-950">
            {heading}
          </h1>
          <p className="relative mt-1 text-sm text-stone-600">
            {personName}’s {device.modelName}
          </p>
        </div>

        <div className="px-6 pb-6 pt-3 text-sm text-stone-700">
          {props.flow === `blockerConnect` && (
            <p>
              You can now manage what’s blocked on {personName}’s {device.type} from
              Gertrude Account. If Blocker still shows a code, open the app again to
              finish connecting.
            </p>
          )}
          {props.flow === `podcasts` && (
            <>
              <p>
                Gertrude Podcasts is linked to {personName}’s {device.type}. Open the app
                again if it still shows a code.
              </p>
              {props.access === `trial` && (
                <p className="mt-3 font-medium text-stone-900">
                  Your free trial is active. Subscribe to Gertrude Light before it ends to
                  keep listening.
                </p>
              )}
              {props.access === `ending` && (
                <Banner variant="warning" className="mt-4">
                  Access ends {props.accessEndsAt ?? `soon`}. Subscribe to Gertrude Light
                  to keep listening.
                </Banner>
              )}
              {props.access === `lapsed` && (
                <Banner variant="warning" className="mt-4">
                  Your free trial has ended. A Gertrude Light subscription is needed to
                  keep using Podcasts.
                </Banner>
              )}
            </>
          )}
          {props.flow === `music` && (
            <>
              <p>
                Gertrude Music is linked to {personName}’s {device.type}. Open the app
                again if it still shows a code.
              </p>
              {props.access === `trialReady` && (
                <p className="mt-3 font-medium text-stone-900">
                  A Music trial is ready to start when the app finishes connecting.
                </p>
              )}
              {props.access === `trial` && (
                <p className="mt-3 font-medium text-stone-900">
                  Your Music trial is active. You can manage it from the device settings.
                </p>
              )}
              {props.access === `unavailable` && (
                <Banner variant="warning" className="mt-4">
                  Music isn’t available right now. Review your plan or billing details to
                  restore access.
                </Banner>
              )}
            </>
          )}
          {props.flow === `blockerSupervise` && (
            <>
              <p>
                {personName}’s {device.type} is linked to your account, but it isn’t
                supervised yet. You’ll need a Mac or Windows computer and a USB cable to
                finish setting up Blocker.
              </p>
              {props.nextStep === `plan` && (
                <p className="mt-3 font-medium text-stone-900">
                  First, check your Gertrude subscription to continue.
                </p>
              )}
              {props.nextStep === `computer` && (
                <p className="mt-3 flex items-center gap-2 font-medium text-stone-900">
                  <LaptopIcon className="h-4 w-4 shrink-0" aria-hidden="true" />
                  Continue on the computer you’ll use for setup.
                </p>
              )}
            </>
          )}
        </div>
        <div className="flex flex-col gap-1.5 border-t border-stone-200 bg-stone-50 px-6 py-5">
          <Button
            type="button"
            variant="primary"
            icon={ArrowRightIcon}
            iconPosition="right"
            onClick={props.onPrimary}
          >
            {primaryLabel}
          </Button>
          {(supervision || needsPlan) && props.onSecondary && (
            <Button type="button" variant="ghost" onClick={props.onSecondary}>
              {supervision ? `Finish later` : `${device.type} settings`}
            </Button>
          )}
        </div>
      </main>
    </div>
  );
};

export default ConnectIosAppResultPage;
