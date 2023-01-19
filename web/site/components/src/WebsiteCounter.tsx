import React, { useState } from 'react';
import cx from 'classnames';
import { useIntersectionObserver, useInterval } from '../../app/lib/hooks';

const WebsiteCounter: React.FC = () => {
  const [totalWebsites, setTotalWebsites] = useState(1938726736);
  const [websitesThisHour, setWebsitesThisHour] = useState(3 * 60 * 60);
  const [websitesToday, setWebsitesToday] = useState(3 * 60 * 60 * 24);
  const [websitesThisWeek, setWebsitesThisWeek] = useState(3 * 60 * 60 * 24 * 7);
  const [websitesSinceVisitingSite, setWebsitesSinceVisitingSite] = useState(0);

  useInterval(() => {
    setTotalWebsites(totalWebsites + 1);
  }, 313);
  useInterval(() => {
    setWebsitesThisHour(websitesThisHour + 1);
  }, 333);
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
    <div className="flex justify-center flex-col pt-12 mt-8 md:mt-20 relative z-10">
      <div className="flex flex-col items-start space-y-2 sm:space-y-3 lg:space-y-6">
        <h2 className="font-inter text-4xl xs:text-5xl sm:text-6xl lg:text-8xl text-white w-[716px]">
          {totalWebsites.toLocaleString()}
        </h2>
        <h3 className="text-2xl sm:text-3xl lg:text-4xl text-white text-opacity-60 font-medium sm:font-bold tracking-wider">
          websites on the internet{` `}
          <a
            href={`https://firstsiteguide.com/how-many-websites/`}
            className="text-gray-600 hover:text-blue-300 transition duration-100"
            target="_blank"
            rel="noreferrer"
          >
            <i className="fa-solid fa-arrow-up-right-from-square text-sm relative bottom-3 -left-1" />
          </a>
        </h3>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mt-16">
        <Statistic
          intersectionMargin="-80px"
          className="col-span-1 lg:col-span-2 hidden md:block"
        >
          <ImportantNumber>{websitesThisWeek.toLocaleString()}</ImportantNumber>
          <InfoText>
            New websites created <Em>this week</Em>
          </InfoText>
          <div className="absolute -right-8 -bottom-8 w-60 h-48 bg-rain rounded-3xl hidden lg:block" />
        </Statistic>
        <Statistic intersectionMargin="-120px" className="order-1 md:order-none">
          <ImportantNumber>3</ImportantNumber>
          <InfoText citation="https://siteefy.com/how-many-websites-are-there/">
            New websites created <Em>every second</Em>
          </InfoText>
        </Statistic>
        <Statistic
          intersectionMargin="-30px"
          className="row-span-1 lg:row-span-2 order-4 md:order-none"
        >
          <ImportantNumber>37%</ImportantNumber>
          <InfoText citation="https://www.bbc.com/news/technology-23030090">
            Of all websites on the internet <Em>are porn</Em>
          </InfoText>
          <div className="absolute -left-8 -bottom-8 w-60 h-60 bg-rain rounded-xl hidden lg:block" />
        </Statistic>
        <Statistic intersectionMargin="40px" className="hidden md:block">
          <ImportantNumber>{websitesThisHour.toLocaleString()}</ImportantNumber>
          <InfoText>
            New websites in the <Em>last hour</Em>
          </InfoText>
        </Statistic>
        <Statistic intersectionMargin="20px" className="order-3 md:order-none">
          <ImportantNumber>{websitesToday.toLocaleString()}</ImportantNumber>
          <InfoText>
            New websites created in the <Em>last 24 hours</Em>
          </InfoText>
        </Statistic>
        <Statistic
          intersectionMargin="0px"
          className="col-span-1 lg:col-span-2 xl:col-span-1 order-2 md:order-none"
        >
          <ImportantNumber>{websitesSinceVisitingSite.toLocaleString()}</ImportantNumber>
          <InfoText>
            New websites created since you visited <Em>this site</Em>
          </InfoText>
        </Statistic>
      </div>
    </div>
  );
};

export default WebsiteCounter;

interface StatisticProps {
  children: React.ReactNode;
  className?: string;
  intersectionMargin: string;
}

const Statistic: React.FC<StatisticProps> = ({
  children,
  className,
  intersectionMargin,
}) => {
  const { ref, intersected } = useIntersectionObserver({
    rootMargin: intersectionMargin,
    threshold: 1,
  });

  return (
    <div
      className={cx(
        `p-10 bg-slate-800 rounded-xl shadow-xl border-gray-700 border-[0.5px] relative overflow-hidden transition duration-200`,
        intersected ? `opacity-100` : `opacity-0 translate-y-4`,
        className,
      )}
      ref={ref}
    >
      {children}
    </div>
  );
};

interface ImportantNumberProps {
  children: React.ReactNode;
}

const ImportantNumber: React.FC<ImportantNumberProps> = ({ children }) => {
  return <h3 className="text-5xl text-white font-inter relative">{children}</h3>;
};

interface EmProps {
  children: React.ReactNode;
}

const Em: React.FC<EmProps> = ({ children }) => {
  return (
    <span className="font-extrabold italic bg-gradient-to-br from-violet-400 to-fuchsia-400 text-transparent bg-clip-text pr-1 relative">
      {children}
    </span>
  );
};

interface InfoTextProps {
  children: React.ReactNode;
  citation?: string;
}

const InfoText: React.FC<InfoTextProps> = ({ children, citation }) => {
  return (
    <p className="mt-4 text-white text-opacity-60 font-medium text-lg relative z-10">
      {children}
      {citation && (
        <a
          href={citation}
          className="text-gray-500 hover:text-blue-300 transition duration-100"
          target="_blank"
          rel="noreferrer"
        >
          <i className="fa-solid fa-arrow-up-right-from-square text-xs relative bottom-1.5 left-0.5" />
        </a>
      )}
    </p>
  );
};
