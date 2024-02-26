'use client'; // delicious donut component https://frontendatscale.com/blog/donut-components/

import React, { useState } from 'react';
import { MenuIcon } from 'lucide-react';
import cx from 'classnames';
import Sidebar from '../../components/docs/Sidebar';

const DocsLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <html>
      <body className="bg-white flex relative overflow-x-hidden">
        <div className="absolute h-[100vw] w-screen -right-[50vh] -top-[50vw] [background:radial-gradient(#fae8ff,transparent_75%)]"></div>
        <Sidebar open={sidebarOpen} setOpen={setSidebarOpen} />
        <main className="flex-grow lg:ml-80">
          <header className="p-6 xs:p-8 flex justify-between lg:hidden">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="bg-slate-100 w-12 h-12 rounded-full flex justify-center items-center text-slate-500"
            >
              <MenuIcon />
            </button>
          </header>
          <div>{children}</div>
        </main>
        <div
          className={cx(
            `fixed w-screen h-screen bg-slate-200/80 backdrop-blur top-0 left-0 transition-opacity duration-300 lg:hidden`,
            sidebarOpen ? `opacity-100` : `opacity-0 pointer-events-none`,
          )}
          onClick={() => setSidebarOpen(false)}
        />
      </body>
    </html>
  );
};

export default DocsLayout;
