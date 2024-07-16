import React from 'react';
import cx from 'classnames';
import { BanIcon, DownloadIcon } from 'lucide-react';
import AppleLogo from '@/public/apple-logo.png';

interface ComputerScreenProps {
  macOpened: boolean;
  downloadButtonClicked: boolean;
  newTabOpened: boolean;
  menuBarAppOpened: boolean;
  unlockRequestClicked: boolean;
  unlockRequestAccepted: boolean;
  className?: string;
}

const ComputerScreen: React.FC<ComputerScreenProps> = ({
  macOpened,
  downloadButtonClicked,
  newTabOpened,
  menuBarAppOpened,
  unlockRequestClicked,
  unlockRequestAccepted,
  className,
}) => (
  <div
    className={cx(
      `w-full h-full bg-gradient-to-b from-violet-300 to-fuchsia-300 relative flex flex-col justify-end items-center p-2`,
      className,
    )}
  >
    {/* dock */}
    <div
      className={cx(
        `bg-white/40 flex gap-2 px-2 py-1.5 rounded-xl transition-[transform] duration-500 delay-[1000ms]`,
        !macOpened && `translate-y-12`,
      )}
    >
      <div className="w-6 h-6 bg-gradient-to-br from-red-500 to-yellow-500 rounded-lg" />
      <div className="w-6 h-6 bg-white flex justify-center items-center rounded-lg">
        <div className="bg-blue-500 w-3 h-3 rounded-full" />
      </div>
      <div className="w-6 h-6 bg-gradient-to-br from-blue-500 to-emerald-500 rounded-lg" />
      <div className="w-6 h-6 bg-white flex justify-center items-center rounded-lg gap-0.5">
        <div className="bg-yellow-500 w-1 h-4 rounded-full" />
        <div className="bg-emerald-500 w-1 h-2 rounded-full" />
      </div>
      <div className="w-6 h-6 bg-white flex justify-center items-center rounded-lg">
        <div className="bg-rose-500 w-2 h-5 rotate-45 rounded-full" />
      </div>
      <div className="w-6 h-6 bg-gradient-to-br from-red-800 to-orange-300 rounded-lg" />
    </div>

    {/* browser window */}
    <div
      className={cx(
        `absolute w-80 h-64 bg-white rounded-lg top-8 left-[calc(50%-160px)] transition-[transform,opacity] duration-500 delay-[1400ms] flex justify-center items-center`,
        !macOpened && `scale-0 translate-y-64 opacity-0`,
      )}
    >
      {/* traffic light */}
      <div className="absolute w-2 h-2 rounded-full bg-red-400 left-2 top-2" />
      <div className="absolute w-2 h-2 rounded-full bg-yellow-400 left-5 top-2" />
      <div className="absolute w-2 h-2 rounded-full bg-green-400 left-8 top-2" />

      {/* url bars/tabs */}
      <div
        className={cx(
          `h-3 top-1.5 absolute bg-slate-200 rounded-full transition-[width,left] duration-300`,
          newTabOpened ? `w-14 left-[calc(50%-68px)]` : `w-28 left-[calc(50%-56px)]`,
        )}
      />
      <div
        className={cx(
          `h-3 top-1.5 absolute bg-slate-200 rounded-full transition-[width,left,opacity] duration-300`,
          newTabOpened
            ? `w-20 left-[calc(50%-8px)]`
            : `w-0 left-[calc(50%+52px)] opacity-0`,
        )}
      />

      {/* download page */}
      <div
        className={cx(
          `mt-4 transition-[transform,opacity] absolute`,
          !macOpened && `opacity-0 scale-75`,
          newTabOpened ? `opacity-0 scale-75 duration-200` : `duration-500 delay-[1.8s]`,
        )}
      >
        {/* download button */}
        <div
          className={cx(
            `text-lg text-white bg-violet-500 rounded-full px-6 py-2 font-medium flex items-center gap-2 transition-[background-color,transform] duration-200 delay-[400ms]`,
            downloadButtonClicked && `bg-violet-600 scale-90`,
          )}
        >
          <span>Download</span>
          <DownloadIcon className="w-5 h-5" strokeWidth={2.5} />
        </div>
      </div>

      {/* blocked page */}
      <div
        className={cx(
          `transition-[opacity,transform] delay-500 duration-300 absolute w-full h-full flex justify-center items-center relative overflow-hidden`,
          !newTabOpened && `opacity-0 translate-y-12 scale-75`,
        )}
      >
        <BanIcon
          className={cx(
            `w-28 h-28 text-red-400`,
            unlockRequestAccepted &&
              `opacity-0 translate-y-8 transition-[opacity,transform] duration-300 delay-300`,
          )}
        />
        <div
          className={cx(
            `absolute w-full h-full left-0 top-0 flex p-2 pt-8 gap-2 transition-[opacity,transform] duration-300 delay-500`,
            !unlockRequestAccepted && `opacity-0 translate-y-8`,
          )}
        >
          <div className="w-16 h-full rounded-xl bg-slate-100"></div>
          <div className="flex-grow flex flex-col gap-2">
            <div className="flex gap-2">
              <div className="w-16 h-16 bg-slate-200 rounded-xl" />
              <div className="flex-grow flex flex-col gap-1.5 justify-center">
                <div className="bg-slate-400 h-2 rounded-full w-24" />
                <div className="bg-slate-200 h-1.5 rounded-full w-full" />
                <div className="bg-slate-200 h-1.5 rounded-full w-full" />
                <div className="bg-slate-200 h-1.5 rounded-full w-20" />
              </div>
            </div>
            <div className="h-8 bg-slate-100 rounded-xl"></div>
            <div className="h-8 bg-slate-100 rounded-xl"></div>
            <div className="flex-grow bg-slate-50 rounded-xl p-2 flex gap-2">
              <div className="bg-slate-200 flex-grow rounded-lg" />
              <div className="bg-slate-100 flex-grow rounded-lg" />
              <div className="bg-slate-300 flex-grow rounded-lg" />
            </div>
          </div>
        </div>
      </div>
    </div>

    {/* menu bar app */}
    <div
      className={cx(
        `absolute top-2 right-2 bg-white/50 border border-slate-200 flex justify-center items-center rounded-xl w-40 h-20 backdrop-blur-xl transition-[transform,opacity] duration-500`,
        (!menuBarAppOpened || unlockRequestAccepted) && `-translate-y-24 opacity-0`,
      )}
    >
      <div
        className={cx(
          `w-24 text-center bg-violet-500 text-white !leading-4 py-2 rounded-lg text-sm transition-[background-color,transform] duration-200`,
          unlockRequestClicked && `scale-95 bg-violet-600`,
        )}
      >
        Request access
      </div>
    </div>

    {/* first cursor */}
    <div
      className={cx(
        `w-4 h-4 bg-black/30 rounded-full absolute transition-[opacity,top,left] duration-500 delay-[2.2s]`,
        macOpened ? `left-52 top-44` : `left-8 top-64 opacity-0`,
        downloadButtonClicked && `!opacity-0`,
      )}
    />

    {/* second cursor */}
    <div
      className={cx(
        `w-4 h-4 bg-black/30 rounded-full absolute transition[opacity,top,left] duration-500 delay-700`,
        menuBarAppOpened ? `left-96 top-12` : `left-52 top-44 opacity-0`,
        unlockRequestClicked && `!opacity-0 !delay-200`,
      )}
    />

    {/* download swoosh effect */}
    <div
      className={cx(
        `absolute w-full h-full left-0 top-0 bg-gradient-to-b from-transparent via-fuchsia-500/50 to-transparent transition-[transform,opacity] duration-1000 ease-out delay-[1.4s]`,
        downloadButtonClicked ? `translate-y-full opacity-0` : `-translate-y-full`,
      )}
    />

    {/* black lock screen */}
    <div
      className={cx(
        `bg-black absolute left-0 top-0 w-full h-full transition-opacity delay-700 duration-500 flex justify-center items-center`,
        macOpened && `opacity-0`,
      )}
    >
      <img
        src={AppleLogo.src}
        alt="Apple logo"
        className="w-16 h-16"
        width={512}
        height={512}
      />
    </div>
  </div>
);

export default ComputerScreen;
