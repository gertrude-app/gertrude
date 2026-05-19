import React from 'react';

interface Props {
  heading: React.ReactNode;
  children: React.ReactNode;
}

const DashboardPage: React.FC<Props> = ({ heading, children }) => {
  return (
    <div className="flex justify-center">
      <div className="flex flex-col px-12 py-16 gap-8 flex-grow max-w-[1200px]">
        {heading}
        {children}
      </div>
    </div>
  );
};

export default DashboardPage;
