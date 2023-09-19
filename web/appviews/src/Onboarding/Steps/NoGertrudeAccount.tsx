import React, { useState } from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';
import QrCode from '../images/signup-qr-code.png';
import QRCode from '../QRCode';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const NoGertrudeAccount: React.FC<Props> = ({ emit }) => {
  const [codeClicked, setCodeClicked] = useState(false);
  return (
    <div className="h-full flex justify-center items-center p-16 gap-12">
      <div>
        <h1 className="text-3xl font-bold">No problem, let's make one!</h1>
        <p className="text-slate-500 mt-4 text-lg max-w-lg">
          It only takes a minute to create an account. We recommend you{` `}
          <b>sign up on your phone,</b> instead of this device. Aim your phone's camera at
          the QR code and it will take you to the signup page.
        </p>
        <p className="text-lg text-slate-500 mt-2 max-w-lg">
          Once you've verified your email, come back here and click to continue.
        </p>
        <div className="flex flex-col gap-4 mt-6 max-w-md">
          <Button
            color="primary"
            size="large"
            type="button"
            onClick={() => emit({ case: `primaryBtnClicked` })}
          >
            Done, I have a gertrude account now{' '}
            <i className="fa-solid fa-arrow-right ml-2" />
          </Button>
          <Button
            color="secondary"
            size="large"
            type="button"
            onClick={() => emit({ case: `secondaryBtnClicked` })}
            className="shadow shadow-violet-200/80"
          >
            I don't want to signup, quit Gertrude
          </Button>
        </div>
      </div>
      <div className="flex flex-col justify-center items-center">
        <div
          className={cx(
            'flex flex-col items-center transition-opacity duration-500',
            codeClicked && `opacity-0`,
          )}
        >
          <span className="text-slate-400 text-sm">Click to see url</span>
          <i className="fa-chevron-down fa-solid text-slate-400 text-sm animate-bounce mt-2 mb-1" />
        </div>
        <div onClick={() => setCodeClicked(true)}>
          <QRCode img={QrCode} url="https://gertrude.app/signup" />
        </div>
      </div>
    </div>
  );
};

export default NoGertrudeAccount;
