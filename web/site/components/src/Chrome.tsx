import React from 'react';
import MainFooter from './MainFooter';
import MainHeader from './MainHeader';

interface Props {
  children: React.ReactNode;
}

const Chrome: React.FC<Props> = ({ children }) => {
  return (
    <main className="overflow-hidden flex flex-col min-h-screen">
      <MainHeader />
      {children}
      <MainFooter />
    </main>
  );
};

export default Chrome;
