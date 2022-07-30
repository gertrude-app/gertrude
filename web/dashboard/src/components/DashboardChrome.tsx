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
      <div
        className={`flex-grow flex flex-col ${
          sidebarExpanded ? `lg:ml-72` : `lg:ml-20`
        } [transition:200ms]`}
      >
        <div
          className={`absolute left-0 top-0 z-30 [transition:700ms] bg-opacity-0 h-screen bg-black w-screen ${
            sidebarOpen ? `block bg-opacity-70` : `hidden`
          }`}
        />
        <header className="justify-start items-center px-5 py-4 fixed w-full shadow z-20 bg-gray-900 bg-gradient-to-br from-transparent via-transparent to-violet-900/50 lg:hidden flex">
          <div
            className="block lg:hidden"
            onClick={() => {
              setSidebarOpen(true);
              setSidebarExpanded(true);
            }}
          >
            <i className="fa fa-bars text-3xl text-white text-opacity-40 hover:text-opacity-60 transition duration-100 cursor-pointer" />
          </div>
        </header>
        <div className="flex-grow bg-gray-50 z-10 mt-16 lg:mt-0">{children}</div>
      </div>
    </div>
  );
};

export default DashboardChrome;
