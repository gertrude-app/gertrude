'use client';

import React, { useState } from 'react';
import cx from 'classnames';
import { useInterval } from '../lib/hooks';
import Stars from './Stars';

const REF_DATE = new Date(2022, 8, 12).getTime();

const DepressingStatisticsBlock: React.FC = () => {
  const [websitesThisHour, setWebsitesThisHour] = useState(3 * 60 * 60);
  const [websitesToday, setWebsitesToday] = useState(3 * 60 * 60 * 24);
  const [websitesThisWeek, setWebsitesThisWeek] = useState(3 * 60 * 60 * 24 * 7);
  const [websitesSinceVisitingSite, setWebsitesSinceVisitingSite] = useState(0);

  useInterval(() => {
    setWebsitesThisHour(websitesThisHour + 1);
  }, 313);
  useInterval(() => {
    setWebsitesToday(websitesToday + 1);
  }, 353);
  useInterval(() => {
    setWebsitesThisWeek(websitesThisWeek + 1);
  }, 323);
  useInterval(() => {
    setWebsitesSinceVisitingSite(websitesSinceVisitingSite + 1);
  }, 343);

  return (
    <section className="xl:p-8 bg-gradient-to-b from-fuchsia-500 to-white">
      <div className="bg-slate-900 px-8 md:px-12 lg:px-20 py-24 md:py-32 lg:py-40 flex items-center flex-col gap-20 rounded-[40px] relative overflow-hidden">
        <Stars className="absolute left-0 top-0 w-full h-176" />
        <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -right-80 -top-80" />
        <div className="[background:radial-gradient(#e879f944,transparent_70%)] w-176 h-176 absolute -left-80 -top-80" />
        <div className="[background:radial-gradient(#a78bfa44,transparent_70%)] w-176 h-176 absolute left-20 -top-96" />
        <div className="flex flex-col 2xl:flex-row justify-center items-center 2xl:items-start gap-12 lg:gap-20 relative">
          <div className="">
            <h2 className="text-7xl font-axiforma md:text-8xl lg:text-[120px] lg:leading-[124px] font-bold w-fit [background-image:radial-gradient(at_top_left,white,transparent_50%),radial-gradient(at_center_150px,#d946ef,transparent_60%),linear-gradient(#8b5cf6,#8b5cf6)] bg-clip-text text-transparent text-center 2xl:text-left 2xl:max-w-xl">
              A losing game
            </h2>
          </div>
          <div className="flex flex-col items-center 2xl:items-start">
            <p
              className={cx(
                `text-xl md:text-2xl text-violet-300 max-w-2xl mb-20 text-center 2xl:text-left`,
              )}
            >
              Most internet safety tools try to block{` `}
              <span className="font-bold text-violet-200">specific categories</span> of
              the internet. With{` `}
              <span className="font-bold text-violet-200">2 billion websites,</span> and
              tens of thousands more being added every day, it's simply impossible to
              maintain up-to-date lists correctly categorizing even a fraction of
              dangerous websites.
            </p>
            <TotalWebsitesCounter />
            <span className="text-violet-300 text-xl xs:text-2xl sm:text-3xl 2xl:self-end mt-1 xs:mt-2 sm:mt-4 2xl:mt-2">
              websites on the internet
            </span>
          </div>
        </div>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 lg:gap-8 max-w-[1500px] -mx-6 xs:mx-0 z-10">
          <Statistic
            statistic={websitesThisWeek}
            label={
              <span>
                New websites created <Bold>this week</Bold>
              </span>
            }
            className="lg:col-span-2"
          />
          <Statistic
            statistic={`37%`}
            label={
              <span>
                Of all websites on the internet <Bold>are porn</Bold>
              </span>
            }
            className="lg:row-span-2"
          />
          <Statistic
            statistic={websitesThisHour}
            label={
              <span>
                New websites in the <Bold>last hour</Bold>
              </span>
            }
          />
          <Statistic
            statistic={websitesToday}
            label={
              <span>
                New websites created in the <Bold>last 24 hours</Bold>
              </span>
            }
          />
          <Statistic
            statistic={websitesSinceVisitingSite}
            label={
              <span>
                New websites created since you visited <Bold>this site</Bold>
              </span>
            }
            className="lg:col-span-2 xl:col-span-1"
          />
          <Statistic
            statistic={3}
            label={
              <span>
                New websites created <Bold>every second</Bold>
              </span>
            }
          />
        </div>
      </div>
    </section>
  );
};

export default DepressingStatisticsBlock;

const TotalWebsitesCounter: React.FC = () => {
  const [totalWebsites, setTotalWebsites] = React.useState(() => {
    const secondsSinceRefDate = Math.floor((Date.now() - REF_DATE) / 1000);
    const newWebsitesSinceRefDate = secondsSinceRefDate * 3;
    return 1_980_000_000 + newWebsitesSinceRefDate;
  });

  useInterval(() => {
    setTotalWebsites(totalWebsites + 1);
  }, 333);
  return (
    <div className="text-white text-5xl xs:text-6xl sm:text-7xl md:text-8xl lg:text-9xl font-mono font-bold flex overflow-hidden">
      {totalWebsites
        .toLocaleString()
        .split(``)
        .map((digit, index) => {
          const isComma = digit === `,`;
          return (
            <div
              key={index}
              className={cx(
                `relative`,
                isComma
                  ? `!-left-2 xs:!-left-3 md:!-left-3 lg:!-left-2 w-4 xs:w-5 md:w-10 lg:w-14`
                  : `w-[32px] xs:w-[40px] sm:w-[48px] md:w-[60px] lg:w-[72px]`,
              )}
            >
              {isComma
                ? digit
                : new Array(10).fill(0).map((_, i) => (
                    <div
                      className={cx(
                        `absolute transition-[top,opacity,filter] duration-300`,
                        {
                          'left-0 top-0': i === Number(digit),
                          'left-0 -top-24 opacity-0 blur-sm':
                            i === Number(digit) + 1 || (i === 0 && Number(digit) === 9),
                          'left-0 top-24 opacity-0 blur-sm':
                            i !== Number(digit) &&
                            i !== Number(digit) + 1 &&
                            (i !== 0 || Number(digit) !== 9),
                        },
                      )}
                      key={i}
                    >
                      {i}
                    </div>
                  ))}
            </div>
          );
        })}
    </div>
  );
};

interface StatisticProps {
  statistic: number | string;
  label: React.ReactNode;
  className?: string;
}

const Statistic: React.FC<StatisticProps> = ({ statistic, label, className }) => (
  <div
    className={cx(
      `p-8 lg:p-10 2xl:p-12 rounded-3xl bg-slate-800 border-slate-900 border`,
      className,
    )}
  >
    <h3 className="text-4xl xs:text-5xl font-mono font-bold text-white">
      {typeof statistic === `string` ? statistic : statistic.toLocaleString()}
    </h3>
    <p className="text-violet-300 text-xl mt-2 xs:mt-4">{label}</p>
  </div>
);

const Bold: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <span className="font-axiforma font-semibold bg-gradient-to-r from-violet-100 to-fuchsia-300 bg-clip-text text-transparent italic">
    {children}
  </span>
);
