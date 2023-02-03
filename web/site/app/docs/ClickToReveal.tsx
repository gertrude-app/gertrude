import React, { useState } from 'react';
import cx from 'classnames';

type Props = {
  title: string;
  children: React.ReactNode;
};

const ClickToReveal: React.FC<Props> = ({ title, children }) => {
  const [revealed, setRevealed] = useState(false);
  return (
    <div className="">
      <div className="flex justify-center">
        <button
          className="text-white uppercase mt-6 font-extrabold bg-gradient-to-br from-indigo-700 to-fuchsia-700 hover:from-indigo-800 hover:to-fuchsia-800 flex items-center px-5 py-1 rounded-lg"
          onClick={() => setRevealed(!revealed)}
        >
          {title}
          <i
            className={cx(`ml-2 fas`, {
              'fa-chevron-right pr-px animate-bounce-right': !revealed,
              'fa-chevron-down': revealed,
            })}
          />
        </button>
      </div>
      <div
        className={cx(
          `-mt-4 pt-5 bg-slate-800 px-5 py-px rounded-2xl`,
          revealed ? `block` : `hidden`,
        )}
      >
        {children}
      </div>
    </div>
  );
};

export default ClickToReveal;
