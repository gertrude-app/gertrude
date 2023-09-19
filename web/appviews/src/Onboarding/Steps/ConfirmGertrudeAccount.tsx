import React from 'react';
import type { AppEvent } from '../onboarding-store';
import { Button } from '@shared/components';

interface Props {
  emit: (event: AppEvent) => unknown;
}

const ConfirmGertrudeAccount: React.FC<Props> = ({ emit }) => (
  <div className="h-full flex flex-col justify-center items-center p-12">
    <div className="flex flex-col justify-center items-center p-12 rounded-3xl shadow-lg bg-white shadow-slate-300/30">
      <h1 className="text-3xl font-bold">Gertrude Account</h1>
      <p className="mt-4 mb-8 text-center text-lg text-slate-500 max-w-2xl">
        In order to use Gertrude, you'll <b>need an account.</b> It's free to try for 60
        days, no credit card required. Do you already have a Gertrude account?
      </p>
      <div className="flex justify-center gap-4">
        <Button
          color="secondary"
          size="large"
          type="button"
          onClick={() => emit({ case: `secondaryBtnClicked` })}
        >
          I don't have an account
        </Button>
        <Button
          color="primary"
          size="large"
          type="button"
          onClick={() => emit({ case: `primaryBtnClicked` })}
        >
          I have a Gertrude acount <i className="fa-solid fa-arrow-right ml-2" />
        </Button>
      </div>
    </div>
  </div>
);

export default ConfirmGertrudeAccount;
