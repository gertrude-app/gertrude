import React from 'react';

interface Props {
  heading: React.ReactNode;
  children: React.ReactNode;
}

const DashboardPage: React.FC<Props> = ({ heading, children }) => (
  <div className="flex justify-center">
    <div className="py-2 min-[940px]:py-16 flex-grow max-w-[1200px] @container/main">
      <div className="px-3 @lg/main:px-4 @xl/main:px-8 @3xl/main:px-12 flex flex-col gap-4 @2xl/main:gap-8">
        {heading}
        {children}
      </div>
    </div>
  </div>
);

export default DashboardPage;
