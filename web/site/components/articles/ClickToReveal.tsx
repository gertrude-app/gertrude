'use client';

import React, { useState } from 'react';
import cx from 'classnames';
import { ChevronDownIcon } from 'lucide-react';

type Props = {
  title: string;
  children: React.ReactNode;
};

const ClickToReveal: React.FC<Props> = ({ title, children }) => {
  const [revealed, setRevealed] = useState(false);
  return (
    <div className="bg-slate-100 my-8 rounded-3xl flex flex-col overflow-hidden">
      <button
        onClick={() => setRevealed(!revealed)}
        className="flex justify-between items-center px-8 py-4 bg-slate-100 hover:bg-slate-200 transition-colors duration-200"
      >
        <span className="text-xl font-semibold bg-gradient-to-r from-violet-700 to-fuchsia-600 bg-clip-text text-transparent">
          {title}
        </span>
        <ChevronDownIcon
          className={cx(
            `text-slate-400 transition-transform duration-200`,
            revealed ? `-rotate-180` : `rotate-0`,
          )}
        />
      </button>
      <div
        className={cx(
          `px-8 transition-transform border-t`,
          revealed ? `h-auto border-slate-200` : `h-0 border-transparent`,
        )}
      >
        {children}
      </div>
    </div>
  );
};

export default ClickToReveal;
