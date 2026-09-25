import { Banner, Button } from '@gertrude/ui';
import { ArrowRightIcon, CheckIcon, CopyIcon, DownloadIcon } from 'lucide-react';
import React from 'react';
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
  | { stage: `plan`; canceled?: boolean; error?: string }
  | { stage: `computerRequired`; onThisIsComputer: () => void }
  | {
      stage: `download`;
      downloaded?: boolean;
      platform?: Platform;
      onDownload: (platform: Platform) => void;
    }
  | { stage: `launch` }
  | { stage: `connect`; code: string; copied?: boolean; onCopy: () => void }
  | { stage: `supervise` }
  | { stage: `checking` }
  | { stage: `finishOnDevice` }
  | { stage: `complete` }
);

const SupervisionSetupPage: React.FC<Props> = (props) => {
  const { device, personName } = props;
  const deviceLabel = `${personName}’s ${device.type}`;
  const deviceModelLabel = `${personName}’s ${device.modelName}`;
  const title =
    props.stage === `plan`
      ? `Get ready to supervise this ${device.type}`
      : props.stage === `computerRequired`
        ? `Continue on a computer`
        : props.stage === `download`
          ? `Download the Supervision Helper`
          : props.stage === `launch`
            ? `Open the Supervision Helper`
            : props.stage === `connect`
              ? `Connect ${deviceLabel} by USB`
              : props.stage === `supervise`
                ? `Supervise ${deviceLabel}`
                : props.stage === `checking`
                  ? `Checking supervision…`
                  : props.stage === `finishOnDevice`
                    ? `Finish on ${deviceLabel}`
                    : `Gertrude Blocker is ready`;
  const step =
    props.stage === `download`
      ? 1
      : props.stage === `launch`
        ? 2
        : props.stage === `connect`
          ? 3
          : props.stage === `supervise` || props.stage === `checking`
            ? 4
            : props.stage === `finishOnDevice`
              ? 5
              : null;
  const primaryLabel =
    props.stage === `plan`
      ? `View subscription options`
      : props.stage === `computerRequired`
        ? `Back to devices`
        : props.stage === `download`
          ? `Next: open the helper`
          : props.stage === `launch`
            ? `The helper is open`
            : props.stage === `connect`
              ? `Next: supervise the device`
              : props.stage === `supervise`
                ? `Check supervision status`
                : props.stage === `finishOnDevice`
                  ? `Check setup status`
                  : `${device.type} settings`;

  return (
    <div className="flex min-h-screen items-center justify-center bg-stone-50 xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat]">
      <main className="min-h-screen w-full bg-white shadow-stone-500/20 xs:my-8 xs:min-h-0 xs:max-w-[420px] xs:overflow-hidden xs:rounded-2xl xs:border xs:border-stone-200 xs:shadow-2xl">
        <header className="relative px-6 pb-5 pt-8 text-center">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_center,rgba(196,180,255,0.16)_0%,transparent_75%),url(/bg.svg)] [background-position:center,center,center] [background-size:1440px_1440px,cover,cover] [mask-image:radial-gradient(ellipse_50%_50%_at_center,black_0%,transparent_100%)]"
          />
          <div
            className={`relative mx-auto flex items-center justify-center ${
              props.stage === `checking` ? `h-24 w-24` : `h-16 w-16`
            }`}
          >
            {props.stage === `checking` && (
              <div
                className="pointer-events-none absolute inset-0 flex items-center justify-center"
                aria-hidden="true"
              >
                <svg
                  className="pairing-loading-ring h-[104px] w-[104px]"
                  viewBox="0 0 104 104"
                >
                  <circle
                    cx="52"
                    cy="52"
                    r="47"
                    fill="none"
                    strokeWidth="3"
                    className="stroke-violet-600/15"
                  />
                  <circle
                    cx="52"
                    cy="52"
                    r="47"
                    fill="none"
                    strokeWidth="3"
                    strokeLinecap="round"
                    pathLength="100"
                    strokeDasharray="24 100"
                    transform="rotate(-90 52 52)"
                    className="stroke-violet-600"
                  />
                </svg>
              </div>
            )}
            <div
              className={
                props.stage === `checking`
                  ? `supervision-checking-device`
                  : props.stage === `complete`
                    ? `supervision-complete-device`
                    : undefined
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
            <div className="space-y-4">
              <p>
                A minimum Gertrude Light subscription is required to supervise this
                {` `}
                {device.type}. The process uses a computer and USB cable, but won’t erase
                the device.
              </p>
              {props.canceled && (
                <Banner variant="warning">
                  Checkout was canceled. You can return to your subscription options when
                  you’re ready.
                </Banner>
              )}
              {props.error && <Banner variant="error">{props.error}</Banner>}
            </div>
          )}

          {props.stage === `computerRequired` && (
            <div className="space-y-4">
              <p>
                To supervise {deviceLabel}, sign in to Gertrude Account on a Mac or
                Windows computer with a USB port. You can pick up where you left off
                without assigning the device again.
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
              Follow the Supervision Helper’s instructions, including turning off Find My
              if prompted. {deviceLabel} will restart during supervision. When the helper
              confirms it’s done, return here to check the status.
            </p>
          )}

          {props.stage === `checking` && (
            <p className="text-center" role="status">
              Keep the Supervision Helper open until it confirms the device is supervised.
              This page will check for the result.
            </p>
          )}

          {props.stage === `finishOnDevice` && (
            <p>
              {deviceLabel} is supervised, but blocking isn’t active yet. After it
              restarts, open Gertrude Blocker on the {device.type} and follow the steps to
              download and install the content-filter profile in Settings. Then return
              here to check that setup is complete.
            </p>
          )}

          {props.stage === `complete` && (
            <p>
              Gertrude Blocker’s filter is active on {deviceLabel}. You can manage its
              block groups from this account. Keep your account password private from
              anyone who shouldn’t change these settings.
            </p>
          )}
        </div>
        <div className="flex flex-col gap-1.5 border-t border-stone-200 bg-stone-50 px-6 py-5">
          {props.stage !== `checking` && (
            <Button
              type="button"
              variant="primary"
              icon={props.stage === `download` ? undefined : ArrowRightIcon}
              iconPosition="right"
              disabled={props.stage === `download` && !props.downloaded}
              onClick={props.onPrimary}
            >
              {primaryLabel}
            </Button>
          )}
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
      </main>
    </div>
  );
};

export default SupervisionSetupPage;
