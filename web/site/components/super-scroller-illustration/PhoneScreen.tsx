import { Logo } from '@shared/components';
import cx from 'classnames';
import { ThumbsDownIcon, ThumbsUpIcon } from 'lucide-react';
import React from 'react';
import ComputerScreen from './ComputerScreen';

interface PhoneScreenProps {
  loginScreenOpened: boolean;
  loggedIn: boolean;
  notificationRecieved: boolean;
  notificationClicked: boolean;
  acceptRequestClicked: boolean;
  reviewingActivity: boolean;
}

const PhoneScreen: React.FC<PhoneScreenProps> = ({
  loginScreenOpened,
  loggedIn,
  notificationRecieved,
  notificationClicked,
  acceptRequestClicked,
  reviewingActivity,
}) => (
  <div
    className={cx(
      `w-full h-full bg-gradient-to-b from-violet-300 to-fuchsia-300 login_screen transition-[opacity,transform] duration-500 rounded-[28px] p-6 flex flex-col justify-center relative overflow-hidden`,
      loginScreenOpened ? `opacity-100` : `opacity-0 scale-75`,
    )}
  >
    {/* white overlay for after logged in */}
    <div
      className={cx(
        `absolute bg-white left-0 top-0 w-full h-full rounded-[28px] transition-opacity duration-1000 delay-500`,
        !loggedIn && `opacity-0`,
      )}
    />

    {/* logo that appears over the white overlay */}
    <Logo
      iconOnly
      className={cx(
        `absolute left-[calc(50%-72px)] z-30 transtion-[transform,opacity] duration-1000 delay-1000`,
        !loggedIn && `translate-y-8 opacity-0`,
        notificationClicked && `translate-y-8 opacity-0 !delay-0 !duration-500`,
      )}
      size={160}
    />

    {/* green glow arround accept button */}
    <div
      className={cx(
        `absolute -right-2 bottom-6 transition-[transform,opacity] w-40 h-40 [background:radial-gradient(#86efac,transparent_75%)] duration-700`,
        acceptRequestClicked ? `scale-[800%] opacity-0` : `scale-0`,
      )}
    ></div>

    {/* accept button */}
    <div
      className={cx(
        `absolute right-8 bottom-16 w-20 h-20 bg-green-500 rounded-full flex justify-center items-center transition-[opacity,transform,background-color] duration-500 delay-500`,
        (!notificationClicked || reviewingActivity) && `opacity-0 translate-y-8`,
        acceptRequestClicked &&
          !reviewingActivity &&
          `!bg-green-700 scale-75 !delay-0 !duration-300`,
      )}
    >
      <ThumbsUpIcon className="text-white w-8 h-8" />
    </div>

    {/* deny button */}
    <div
      className={cx(
        `absolute left-8 bottom-16 w-20 h-20 bg-red-500 rounded-full flex justify-center items-center transition-[opacity,transform] duration-500 delay-700`,
        (!notificationClicked || reviewingActivity) && `opacity-0 translate-y-8`,
      )}
    >
      <ThumbsDownIcon className="text-white w-8 h-8" />
    </div>

    {/* notification */}
    <div
      className={cx(
        `absolute z-40 w-[calc(100%-16px)] left-2 bg-slate-200/50 backdrop-blur-lg p-4 rounded-2xl flex items-center gap-4 top-12 transition-[transform] duration-500 delay-200`,
        !notificationRecieved && `-translate-y-36`,
      )}
    >
      <div className="w-10 h-10 bg-white rounded-xl flex justify-center items-center">
        <Logo iconOnly size={40} />
      </div>
      <div>
        <h2 className="font-medium">New unlock request!</h2>
        <p className="text-black/50 text-sm">Click to allow or deny</p>
      </div>
    </div>

    {/* login form */}
    <div
      className={cx(
        `bg-white p-6 rounded-3xl flex flex-col gap-4 transition-[opacity,transform] duration-500 delay-300 relative`,
        !loginScreenOpened && `opacity-0 translate-y-8`,
        loggedIn && `-translate-x-80`,
      )}
    >
      {/* email field */}
      <div className="h-12 bg-slate-100 rounded-full flex items-center pl-5 text-lg font-medium text-slate-400">
        {`me@example.com`.split(``).map((char, index) => (
          <span
            key={index}
            className={cx(
              `transition-[transform,opacity]`,
              !loginScreenOpened && `scale-0 opacity-0`,
            )}
            style={{
              transitionDelay: `${index * 50 + 700}ms`,
            }}
          >
            {char}
          </span>
        ))}
      </div>

      {/* password field */}
      <div className="h-12 bg-slate-100 rounded-full flex items-center pl-6 gap-1">
        {[...Array(10)].map((_, index) => (
          <span
            key={index}
            className={cx(
              `transition-[transform,opacity] w-2 h-2 rounded-full bg-slate-400 inline-block`,
              !loginScreenOpened && `scale-0 opacity-0`,
            )}
            style={{
              transitionDelay: `${index * 50 + 1400}ms`,
            }}
          ></span>
        ))}
      </div>

      {/* login button */}
      <div
        className={cx(
          `w-28 h-12 rounded-full self-end border border-slate-200 flex justify-center items-center text-lg text-slate-500 transition-[background-color,transform] duration-200 delay-[2200ms] font-medium`,
          loginScreenOpened && `bg-slate-200 scale-90`,
        )}
      >
        Log in
      </div>
    </div>

    {/* activity */}
    <div
      className={cx(
        `flex flex-col absolute left-0 top-0 w-full h-full items-center transition-[transform] delay-[2s] duration-1000`,
        reviewingActivity && `-translate-y-52`,
      )}
    >
      <ComputerScreen
        macOpened={true}
        downloadButtonClicked={true}
        newTabOpened={true}
        menuBarAppOpened={true}
        unlockRequestClicked={true}
        unlockRequestAccepted={true}
        className={cx(
          `!w-128 !h-96 scale-[50%] rounded-2xl shrink-0 transition-[opacity,transform] duration-500 delay-1000`,
          !reviewingActivity && `opacity-0 translate-y-8`,
        )}
      />
      <ComputerScreen
        macOpened={true}
        downloadButtonClicked={true}
        newTabOpened={true}
        menuBarAppOpened={true}
        unlockRequestClicked={false}
        unlockRequestAccepted={false}
        className={cx(
          `!w-128 !h-96 scale-[50%] rounded-2xl shrink-0 -mt-40 overflow-hidden transition-[opacity,transform] duration-500 delay-[1.1s]`,
          !reviewingActivity && `opacity-0 translate-y-8`,
        )}
      />
      <ComputerScreen
        macOpened={true}
        downloadButtonClicked={false}
        newTabOpened={false}
        menuBarAppOpened={false}
        unlockRequestClicked={false}
        unlockRequestAccepted={false}
        className={cx(
          `!w-128 !h-96 scale-[50%] rounded-2xl shrink-0 -mt-40 overflow-hidden transition-[opacity,transform] duration-500 delay-[1.2s]`,
          !reviewingActivity && `opacity-0 translate-y-8`,
        )}
      />
    </div>
  </div>
);

export default PhoneScreen;
