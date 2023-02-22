import React from 'react';

interface Props {
  width: number;
  height: number;
  children: React.ReactNode;
}

const AppWindow: React.FC<Props> = ({ children, width, height }) => {
  return (
    <div
      className={`w-[${width}px] h-[${height}px] shadow-lg flex flex-col border-[0.5px] rounded-xl border-slate-300`}
    >
      <div className="flex items-center pl-2 space-x-1.5 bg-[rgb(239,237,242)] h-[28px] rounded-t-xl border-b-[0.5px] border-slate-300">
        <div className="w-[12px] h-[12px] rounded-full border-[0.5px] border-slate-400 bg-[rgb(238,105,94)]" />
        <div className="w-[12px] h-[12px] rounded-full border-[0.5px] border-slate-400 bg-[rgb(246,189,79)]" />
        <div className="w-[12px] h-[12px] rounded-full border-[0.5px] border-slate-400 bg-[rgb(97,196,84)]" />
      </div>
      <div className="flex-grow">{children}</div>
    </div>
  );
};

export default AppWindow;
