import React from 'react';
import { Link } from 'react-router-dom';
import DashboardChrome from '../DashboardChrome';

const App: React.FC = () => {
  return (
    <DashboardChrome>
      <div className="p-8">
        <h1>Pages:</h1>
        <br />
        <Link to="/profile">Profile</Link>
        <br />
        <Link to="/monitoring">Monitoring</Link>
        <br />
        <Link to="/day-view">Monitoring day view</Link>
        <br />
        <Link to="/protected-users">Protected users</Link>
      </div>
    </DashboardChrome>
  );
};

export default App;
