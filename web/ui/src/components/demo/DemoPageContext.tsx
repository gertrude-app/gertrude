import React from 'react';

interface DemoPageContextValue {
  sourceBasePath: string;
}

export const DemoPageContext = React.createContext<DemoPageContextValue | null>(null);

export const useDemoPageContext = (): DemoPageContextValue => {
  const context = React.useContext(DemoPageContext);

  if (!context) {
    throw new Error('DemoExample must be rendered inside ComponentDemoPage');
  }

  return context;
};
