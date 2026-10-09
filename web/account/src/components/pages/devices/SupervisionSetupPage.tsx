import { Banner, Button } from '@gertrude/ui';
import { ArrowRightIcon, CheckIcon, CopyIcon, DownloadIcon } from 'lucide-react';
import React from 'react';
import PairingPageLayout, { PairingHeaderBackground } from './PairingPageLayout';
import { burstConfetti } from './burstConfetti';
import DeviceArtwork from '#/components/people/DeviceArtwork';

type Platform = `mac` | `windows`;

type Props = {
  device: {
    type: `iPhone` | `iPad`;
    modelName: string;
    modelIdentifier: string;
  };
  personName: string;
  onPrimary: () => void;
  onFinishLater?: () => void;
} & (
  | { stage: `plan` }
  | { stage: `computerRequired`; onThisIsComputer: () => void }
  | {
      stage: `download`;
      downloaded?: boolean;
      platform?: Platform;
      onDownload: (platform: Platform) => void;
    }
  | { stage: `launch` }
  | { stage: `connect`; code: string; copied?: boolean; onCopy: () => void }
  | { stage: `supervise` | `finishOnDevice`; checking?: boolean; error?: string }
  | { stage: `complete` }
);

const SupervisionSetupPage: React.FC<Props> = (props) => {
  const { device, personName } = props;
  const deviceLabel = `${personName}’s ${device.type}`;
  const deviceModelLabel = `${personName}’s ${device.modelName}`;
  const canCheck = props.stage === `supervise` || props.stage === `finishOnDevice`;
  const checking = canCheck && props.checking;
  const { title, step, primaryLabel } = {
    plan: {
      title: `Get ready to supervise this ${device.type}`,
      step: null,
      primaryLabel: `View subscription options`,
    },
    computerRequired: {
      title: `Continue on a computer`,
      step: null,
      primaryLabel: `Back to devices`,
    },
    download: {
      title: `Download the Supervision Helper`,
      step: 1,
      primaryLabel: `Next: open the helper`,
    },
    launch: {
      title: `Open the Supervision Helper`,
      step: 2,
      primaryLabel: `The helper is open`,
    },
    connect: {
      title: `Connect ${deviceLabel} by USB`,
      step: 3,
      primaryLabel: `Next: supervise the device`,
    },
    supervise: {
      title: `Supervise ${deviceLabel}`,
      step: 4,
      primaryLabel: `Check supervision status`,
    },
    finishOnDevice: {
      title: `Finish on ${deviceLabel}`,
      step: 5,
      primaryLabel: `Check setup status`,
    },
    complete: {
      title: `Gertrude Blocker is ready`,
      step: null,
      primaryLabel: `${device.type} settings`,
    },
  }[props.stage];

  return (
    <PairingPageLayout>
      <header className="relative px-6 pb-5 pt-8 text-center">
        <PairingHeaderBackground />
        <div className="relative mx-auto flex h-16 w-16 items-center justify-center">
          <div
            className={
              props.stage === `complete` ? `supervision-complete-device` : undefined
            }
            onAnimationEnd={props.stage === `complete` ? burstConfetti : undefined}
          >
            <div className="scale-[1.35]">
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
        {step !== null && (
          <div className="relative mt-4 flex items-center justify-center gap-2 text-xs font-medium text-violet-900/70">
            <svg className="h-3 w-3" viewBox="0 0 16 16" aria-hidden="true">
              <circle
                cx="8"
                cy="8"
                r="6"
                fill="none"
                strokeWidth="2.5"
                className="stroke-violet-600/15"
              />
              <circle
                cx="8"
                cy="8"
                r="6"
                fill="none"
                strokeWidth="2.5"
                strokeLinecap={step === 5 ? `butt` : `round`}
                pathLength="100"
                strokeDasharray={`${step === 5 ? 95 : step * 20} 100`}
                transform="rotate(-90 8 8)"
                className="stroke-violet-600"
              />
            </svg>
            <span>Step {step} of 5</span>
          </div>
        )}
        <h1
          className={`relative text-xl font-semibold leading-tight text-stone-950 ${
            step === null ? `mt-6` : `mt-2`
          }`}
        >
          {title}
        </h1>
        {props.stage !== `complete` && (
          <p className="relative mt-1 text-sm text-stone-600">{deviceModelLabel}</p>
        )}
      </header>

      <div className="px-6 pb-6 text-sm text-stone-700">
        {props.stage === `plan` && (
          <p>
            A minimum Gertrude Light subscription is required to supervise this
            {` `}
            {device.type}. The process uses a computer and USB cable, but won’t erase the
            device.
          </p>
        )}

        {props.stage === `computerRequired` && (
          <div className="space-y-4">
            <p>
              To supervise {deviceLabel}, sign in to Gertrude Account on a Mac or Windows
              computer with a USB port. Open Devices and choose Continue setup for{` `}
              {deviceLabel}. You won’t need to assign the device again.
            </p>
          </div>
        )}

        {props.stage === `download` && (
          <div className="space-y-4">
            <p>
              The Supervision Helper is a one-time app for your computer. It guides you
              through connecting {deviceLabel} by USB without erasing it.
            </p>
            <div className="grid gap-2 xs:grid-cols-2">
              <Button
                type="button"
                variant={props.platform === `mac` ? `selected` : `default`}
                icon={DownloadIcon}
                onClick={() => props.onDownload(`mac`)}
                className="w-full"
              >
                Mac
              </Button>
              <Button
                type="button"
                variant={props.platform === `windows` ? `selected` : `default`}
                icon={DownloadIcon}
                onClick={() => props.onDownload(`windows`)}
                className="w-full"
              >
                Windows
              </Button>
            </div>
            {props.platform === `windows` && (
              <Banner variant="warning">
                If Windows says the app isn’t commonly downloaded, choose Keep or Keep
                anyway. When opening it, choose More info, then Run anyway.
              </Banner>
            )}
            {props.downloaded && (
              <p className="flex items-start gap-3 font-medium text-stone-900">
                <CheckIcon
                  className="mt-0.5 h-4 w-4 shrink-0 text-green-600"
                  aria-hidden="true"
                />
                Download started. Next, open the helper on this computer.
              </p>
            )}
          </div>
        )}

        {props.stage === `launch` && (
          <div className="space-y-4">
            <p>Find the file you downloaded, then open Gertrude Supervisor.</p>
            <ol className="space-y-3 py-2 pl-3">
              <li className="flex gap-3">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-700">
                  1
                </span>
                <span>Look in your Downloads folder or your browser’s downloads.</span>
              </li>
              <li className="flex gap-3">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-700">
                  2
                </span>
                <span>If the file ends in .zip, double-click to unzip it first.</span>
              </li>
              <li className="flex gap-3">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-violet-100 text-xs font-semibold text-violet-700">
                  3
                </span>
                <span>Open the Gertrude Supervisor app.</span>
              </li>
            </ol>
          </div>
        )}

        {props.stage === `connect` && (
          <div className="space-y-4">
            <p>
              Plug {deviceLabel} into this computer. If asked on the device, tap Trust.
              Then enter this code in the Supervision Helper:
            </p>
            <div className="py-5 text-center">
              <div
                role="group"
                aria-label={`Supervision code ${props.code}`}
                className="font-mono text-3xl font-semibold tracking-[0.2em] text-violet-950 tabular-nums xs:text-4xl"
              >
                <span aria-hidden="true">{props.code.slice(0, 3)}</span>
                <span aria-hidden="true" className="ml-2.5">
                  {props.code.slice(3)}
                </span>
              </div>
              <Button
                type="button"
                variant="default"
                size="small"
                icon={props.copied ? CheckIcon : CopyIcon}
                onClick={props.onCopy}
                className="mt-4"
              >
                {props.copied ? `Copied` : `Copy code`}
              </Button>
            </div>
          </div>
        )}

        {props.stage === `supervise` && (
          <p>
            Follow the Supervision Helper’s instructions, including turning off Find My if
            prompted. {deviceLabel} will restart during supervision. When the helper
            confirms it’s done, return here to check the status.
          </p>
        )}

        {props.stage === `finishOnDevice` && (
          <p>
            {deviceLabel} is supervised, but blocking isn’t active yet. After it restarts,
            open Gertrude Blocker on the {device.type} and follow the steps to download
            and install the content-filter profile in Settings. Then return here to check
            that setup is complete.
          </p>
        )}

        {props.stage === `complete` && (
          <p>
            Gertrude Blocker’s filter is active on {deviceLabel}. You can manage its block
            groups from this account. Keep your account password private from anyone who
            shouldn’t change these settings.
          </p>
        )}
        {canCheck && props.error && !checking && (
          <div role="alert" className="mt-4">
            <Banner variant="error">{props.error}</Banner>
          </div>
        )}
      </div>
      <div className="flex flex-col gap-1.5 border-t border-stone-200 bg-stone-50 px-6 py-5">
        <Button
          type="button"
          variant="primary"
          icon={props.stage === `download` ? undefined : ArrowRightIcon}
          iconPosition="right"
          loading={checking}
          disabled={props.stage === `download` && !props.downloaded}
          onClick={props.onPrimary}
        >
          {checking ? `Checking…` : primaryLabel}
        </Button>
        {props.stage === `computerRequired` && (
          <Button type="button" variant="ghost" onClick={props.onThisIsComputer}>
            I’m on a computer
          </Button>
        )}
        {props.onFinishLater &&
          props.stage !== `computerRequired` &&
          props.stage !== `complete` && (
            <Button type="button" variant="ghost" onClick={props.onFinishLater}>
              Finish later
            </Button>
          )}
      </div>
    </PairingPageLayout>
  );
};

export default SupervisionSetupPage;
