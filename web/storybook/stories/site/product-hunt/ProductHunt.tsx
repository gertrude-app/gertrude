import { Logo } from '@shared/components';
import React from 'react';
import Blocked from '../../static/blocked-requests.png';
import DashProtectFamily from '../../static/protect-family.png';
import Gradient from '../../static/purple-gradient.png';
import DashUnlockRequest from '../../static/unlock-request.png';

export const ProtectFamily: React.FC = () => (
  <GradientWrap>
    <div className="flex items-center justify-center gap-4 mt-12">
      <Logo type="inverted" size={60} textSize="text-[0px]" className="-ml-4" />
      <div className="text-white text-[50px] text-opacity-70 font-bold">
        Protect and monitor the{` `}
        <b className="text-opacity-100 text-white font-extrabold">entire family.</b>
      </div>
    </div>
    <div
      className="w-[1058px] h-[826px] shadow-2xl rounded-2xl absolute bottom-[-220px] left-[105px]"
      style={{
        background: `url(${DashProtectFamily.src})`,
      }}
    ></div>
  </GradientWrap>
);

export const UnlockRequest: React.FC = () => (
  <GradientWrap>
    <div className="flex items-center justify-center gap-4 mt-12">
      <Logo type="inverted" size={60} textSize="text-[0px]" className="-ml-4" />
      <div className="text-white text-[50px] text-opacity-70 font-bold">
        Respond on your device to{` `}
        <b className="text-opacity-100 text-white font-extrabold">unlock requests.</b>
      </div>
    </div>
    <div
      className="w-[1006px] h-[626px] scale-[87%] shadow-2xl rounded-xl absolute bottom-[20px] left-[145px]"
      style={{
        background: `url(${DashUnlockRequest.src})`,
      }}
    ></div>
  </GradientWrap>
);

export const BlockedRequests: React.FC = () => (
  <GradientWrap>
    <div className="flex items-center justify-center gap-4 mt-12">
      <Logo type="inverted" size={60} textSize="text-[0px]" className="-ml-4" />
      <div className="text-white text-[50px] text-opacity-70 font-bold">
        Easily see what needs to be{` `}
        <b className="text-opacity-100 text-white font-extrabold">unlocked.</b>
      </div>
    </div>
    <div
      className="w-[1800px] h-[1050px] scale-[65%] shadow-22xl rounded-3xl absolute bottom-[-280px] left-[-260px]"
      style={{
        background: `url(${Blocked.src})`,
      }}
    ></div>
  </GradientWrap>
);

const GradientWrap: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <section
    className="w-[1270px] h-[760px] flex flex-col relative overflow-hidden"
    style={{ background: `url(${Gradient.src})` }}
  >
    {children}
  </section>
);
