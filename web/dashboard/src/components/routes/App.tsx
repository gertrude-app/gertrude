import React from 'react';
import DashboardChrome from '../DashboardChrome';

const App: React.FC = () => {
  const page = location.pathname.split('/')[1];
  console.log(page);
  return (
    <DashboardChrome>
      <h1>hello world</h1>
    </DashboardChrome>
  );
};

export default App;
