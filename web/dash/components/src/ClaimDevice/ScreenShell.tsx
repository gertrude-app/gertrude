import React from 'react';
import PageHeading from '../PageHeading';

const ScreenShell: React.FC<{
  title: string;
  children: React.ReactNode;
}> = ({ title, children }) => (
  <div className="relative max-w-3xl">
    <PageHeading icon="phone">{title}</PageHeading>
    <div className="mt-8 bg-white rounded-2xl border border-slate-200 p-6">
      {children}
    </div>
  </div>
);

export default ScreenShell;
