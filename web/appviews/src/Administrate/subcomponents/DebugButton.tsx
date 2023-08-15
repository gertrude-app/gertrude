import React, { useState } from 'react';
import cx from 'classnames';

const DebugButton: React.FC = () => {
  const [debuggerOpen, setDebuggerOpen] = useState(false);
  const [debugging, setDebugging] = useState(false);

  return (
    <div
      className={cx(
        `rounded-xl border-slate-200 dark:border-slate-800 border flex items-center justify-start overflow-hidden duration-200 transition-[width]`,
        debuggerOpen ? `w-[200px]` : `w-[42px]`,
      )}
    >
      <button
        className="rounded-xl text-xl w-10 h-10 text-slate-400 dark:text-slate-600 hover:bg-slate-50 dark:hover:bg-slate-800 hover:text-slate-500 transition-colors duration-100 shrink-0 relative flex justify-center items-center"
        onClick={() => setDebuggerOpen(!debuggerOpen)}
      >
        <i
          className={cx(
            `fa-solid fa-circle text-xs transition duration-100 absolute animate-ping text-red-500`,
            debugging ? `block` : `hidden`,
          )}
        />
        <i
          className={cx(
            `fa-solid transition duration-100 relative`,
            debugging ? `fa-circle text-[10px] text-red-500` : `fa-bug-slash`,
          )}
        />
      </button>
      <button
        className={cx(
          `mx-1.5 bg-slate-50 dark:bg-slate-900 text-slate-500 dark:text-slate-400 font-medium border-[0.5px] border-slate-200 dark:border-slate-600 hover:border-slate-300 hover:bg-white hover:text-slate-600 dark:hover:bg-slate-800 transition-[border-color,background-color,color,opacity] duration-200 rounded-lg px-2 py-0.5 active:scale-95 whitespace-nowrap`,
          debuggerOpen ? `opacity-100` : `opacity-0`,
        )}
        onClick={() => setDebugging(!debugging)}
      >
        {debugging ? `Stop debugging` : `Send debug data`}
      </button>
    </div>
  );
};

export default DebugButton;
