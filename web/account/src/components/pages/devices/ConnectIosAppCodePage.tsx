import { Button, LoadingDots } from '@gertrude/ui';
import { ArrowLeftIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import PairingPageLayout, { PairingHeaderBackground } from './PairingPageLayout';

type Props = {
  appName: string;
  appIconUrl: string;
} & (
  | { state: `checking` }
  | { state: `invalid` | `expired`; onBack: () => void }
  | { state: `error`; onBack: () => void; onRetry: () => void }
);

const ConnectIosAppCodePage: React.FC<Props> = (props) => {
  const loading = props.state === `checking`;
  const title =
    props.state === `checking`
      ? `Checking the code…`
      : props.state === `invalid`
        ? `We couldn’t find that code`
        : props.state === `expired`
          ? `This code has expired`
          : `Couldn’t check the code`;

  return (
    <PairingPageLayout>
      <header className="relative px-6 pb-5 pt-8 text-center">
        <PairingHeaderBackground />
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
      </header>

      <div
        className={`px-6 pb-6 text-sm text-stone-700 ${
          props.state === `checking` || props.state === `error` ? `text-center` : ``
        }`}
        role={loading ? `status` : `alert`}
      >
        {props.state === `checking` && <p>Checking which device this code belongs to.</p>}
        {props.state === `invalid` && (
          <p>
            Open {props.appName} on the iPhone or iPad and check the six-digit code or
            link, then try again from the app.
          </p>
        )}
        {props.state === `expired` && (
          <p>
            Open {props.appName} on the iPhone or iPad to get a new code, then use its new
            link to continue.
          </p>
        )}
        {props.state === `error` && <p>Check your internet connection and try again.</p>}
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
    </PairingPageLayout>
  );
};

export default ConnectIosAppCodePage;
