import React, { useState } from 'react';
import SidebarNav from './SidebarNav';

interface Props {
  children: React.ReactNode;
}

const DashboardChrome: React.FC<Props> = ({ children }) => {
  const [sidebarExpanded, setSidebarExpanded] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div className="min-h-screen flex">
      <SidebarNav
        expanded={sidebarExpanded}
        setExpanded={setSidebarExpanded}
        open={sidebarOpen}
        setOpen={setSidebarOpen}
      />
      <div className="flex-grow flex flex-col">
        <div className="flex justify-between items-center p-5 border-b-2 z-20 h-16 bg-white">
          <div className="block lg:hidden" onClick={() => setSidebarOpen(true)}>
            <i className="fa fa-bars text-3xl text-gray-400 hover:text-gray-500 transition duration-100 cursor-pointer" />
          </div>
          <h2></h2>
          <h2>stuff</h2>
        </div>
        <div className="flex-grow bg-gray-50 z-10">{children}</div>
      </div>
    </div>
  );
};

export default DashboardChrome;
