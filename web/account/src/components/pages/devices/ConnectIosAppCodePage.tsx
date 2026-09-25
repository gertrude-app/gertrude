import { Button, LoadingDots } from '@gertrude/ui';
import { ArrowLeftIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';

type Props = {
  appName: string;
  appIconUrl: string;
} & (
  | { state: `checking` }
  | { state: `resuming`; modelName: string }
  | { state: `invalid` | `expired`; onBack: () => void }
  | { state: `error`; onBack: () => void; onRetry: () => void }
);

const ConnectIosAppCodePage: React.FC<Props> = (props) => {
  const loading = props.state === `checking` || props.state === `resuming`;
  const title =
    props.state === `checking`
      ? `Checking the code…`
      : props.state === `resuming`
        ? `Picking up where you left off…`
        : props.state === `invalid`
          ? `We couldn’t find that code`
          : props.state === `expired`
            ? `This code has expired`
            : `Couldn’t check the code`;

  return (
    <div className="flex min-h-screen items-center justify-center bg-stone-50 xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat]">
      <main className="min-h-screen w-full bg-white shadow-stone-500/20 xs:my-8 xs:min-h-0 xs:max-w-[420px] xs:overflow-hidden xs:rounded-2xl xs:border xs:border-stone-200 xs:shadow-2xl">
        <header className="relative px-6 pb-5 pt-8 text-center">
          <div
            aria-hidden="true"
            className="pointer-events-none absolute inset-0 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_center,rgba(196,180,255,0.16)_0%,transparent_75%),url(/bg.svg)] [background-position:center,center,center] [background-size:1440px_1440px,cover,cover] [mask-image:radial-gradient(ellipse_50%_50%_at_center,black_0%,transparent_100%)]"
          />
          <div className="relative mx-auto flex h-20 w-20 items-center justify-center">
            {loading ? (
              <LoadingDots size="large" ariaHidden />
            ) : (
              <img
                src={props.appIconUrl}
                alt=""
                className="h-12 w-12 rounded-2xl shadow-sm"
              />
            )}
          </div>
          <h1 className="relative mt-5 text-xl font-semibold leading-tight text-stone-950">
            {title}
          </h1>
          {props.state === `resuming` && (
            <p className="relative mt-1 text-sm text-stone-600">{props.modelName}</p>
          )}
        </header>

        <div
          className={`px-6 pb-6 text-sm text-stone-700 ${
            props.state === `checking` || props.state === `error` ? `text-center` : ``
          }`}
          role={loading ? `status` : `alert`}
        >
          {props.state === `checking` && (
            <p>Checking which device this code belongs to.</p>
          )}
          {props.state === `resuming` && (
            <p>
              This device is already assigned to your account. Finding the right place to
              continue so you don’t have to start over.
            </p>
          )}
          {props.state === `invalid` && (
            <p>
              Open {props.appName} on the iPhone or iPad and check the six-digit code or
              link, then try again from the app.
            </p>
          )}
          {props.state === `expired` && (
            <p>
              Open {props.appName} on the iPhone or iPad to get a new code, then use its
              new link to continue.
            </p>
          )}
          {props.state === `error` && (
            <p>Check your internet connection and try again.</p>
          )}
        </div>

        {!loading && (
          <div className="flex flex-col gap-1.5 border-t border-stone-200 bg-stone-50 px-6 py-5">
            {props.state === `error` && (
              <Button
                type="button"
                variant="primary"
                icon={RefreshCwIcon}
                onClick={props.onRetry}
              >
                Try again
              </Button>
            )}
            <Button
              type="button"
              variant={props.state === `error` ? `ghost` : `default`}
              icon={props.state === `error` ? undefined : ArrowLeftIcon}
              onClick={props.onBack}
            >
              Back to Account
            </Button>
          </div>
        )}
      </main>
    </div>
  );
};

export default ConnectIosAppCodePage;
