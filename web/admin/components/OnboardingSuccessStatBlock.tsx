import React from 'react';
import type { AdminData } from '@/lib/types';
import { isOnboarded } from '@/lib/utils';

const OnboardingSuccessStatBlock: React.FC<{ admins: AdminData[] }> = ({ admins }) => {
  const successfulAdmins = admins.filter(isOnboarded);
  const successRate = Math.round((successfulAdmins.length / admins.length) * 100);

  return (
    <div className="border-4 border-violet-500 h-20 rounded-3xl flex justify-start p-1.5">
      <div
        className="bg-gradient-to-r from-violet-500 to-fuchsia-500 rounded-2xl flex justify-center items-center"
        style={{ width: `${successRate}%` }}
      >
        <span className="text-white text-2xl font-semibold text-center !leading-[1em]">
          {successRate}% of signups successfully onboard
        </span>
      </div>
      <div className="flex-grow flex justify-center items-center bg-slate-100 text-xl font-medium text-slate-400 rounded-2xl ml-2">
        <span>{100 - successRate}% don't</span>
      </div>
    </div>
  );
};

export default OnboardingSuccessStatBlock;
