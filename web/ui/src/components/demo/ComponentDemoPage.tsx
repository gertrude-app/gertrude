import React from 'react';
import { useLocation } from '@tanstack/react-router';
import { DemoPageContext } from './DemoPageContext';

interface Props {
  title: string;
  description: string;
  children: React.ReactNode;
}

const routePathToSourceBasePath = (pathname: string): string => {
  const routePath = pathname.replace(/\/$/, '');
  return `/src/routes${routePath === '' ? '' : routePath}`;
};

const ComponentDemoPage: React.FC<Props> = ({ title, description, children }) => {
  const location = useLocation();
  const sourceBasePath = routePathToSourceBasePath(location.pathname);

  return (
    <DemoPageContext.Provider value={{ sourceBasePath }}>
      <div className="min-h-screen bg-stone-100 px-6 py-10 text-stone-950 lg:px-10 lg:py-14">
        <div className="mx-auto flex max-w-6xl flex-col gap-10">
          <header className="max-w-3xl">
            <h1 className="text-3xl font-medium tracking-tight text-stone-950 sm:text-4xl">
              {title}
            </h1>
            <p className="mt-4 text-lg leading-8 text-stone-600">{description}</p>
          </header>

          <div className="flex flex-col gap-14">{children}</div>
        </div>
      </div>
    </DemoPageContext.Provider>
  );
};

export default ComponentDemoPage;
