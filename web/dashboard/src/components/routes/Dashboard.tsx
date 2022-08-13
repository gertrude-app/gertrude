import React from 'react';
import { Link } from 'react-router-dom';

const Dashboard: React.FC = () => (
  <div className="p-8">
    <h1>Pages:</h1>
    <br />
    <Link to="/profile">Profile</Link>
    <br />
    <Link to="/monitoring">Monitoring</Link>
    <br />
    <Link to="/day-view">Monitoring day view</Link>
    <br />
    <Link to="/users">Users</Link>
  </div>
);

export default Dashboard;
