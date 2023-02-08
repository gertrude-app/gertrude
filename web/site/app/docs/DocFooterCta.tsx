import React from 'react';
import { Logo } from '@shared/components';

const DocFooterCta: React.FC = () => (
  <div className="mt-16 flex flex-col gap-3 rounded-lg bg-gradient-to-br from-violet-600 to-fuchsia-500 p-6 text-white sm:flex-row sm:items-start sm:gap-8">
    <Logo type="inverted" textSize="text-3xl" size={45} />
    <div className="flex flex-col items-end">
      <p className="text-base leading-6">
        The Gertrude app helps you <b>protect your kids</b> online with{` `}
        <b>strict internet filtering</b> that you can manage from your{` `}
        <b>own computer or phone,</b> plus remote monitoring of screenshots and
        keystrokes. $5/mo, with a 60 day free trial.
      </p>
      <a
        className="mt-2 inline-flex rounded-lg bg-white px-4 py-1.5 text-sm font-bold text-violet-500"
        href="https://dash.gertrude.app/signup"
      >
        Start free trial &rarr;
      </a>
    </div>
  </div>
);

export default DocFooterCta;
