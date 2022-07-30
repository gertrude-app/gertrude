import React from 'react';
import { Link } from 'react-router-dom';
import DashboardChrome from '../DashboardChrome';

const MonitoringDayView: React.FC = () => {
  return (
    <DashboardChrome>
      <main className="flex flex-col min-h-screen">
        <header className="flex itesm-center justify-between py-4 px-6 border-b-2 bg-gray-50">
          <div className="flex items-center">
            <Link
              to="/monitoring"
              className="flex items-center mr-6 text-gray-500 hover:text-gray-600 transition duration-75 text-lg"
            >
              <i className="fa fa-chevron-left text-lg mr-2" /> Back
            </Link>
            <h1 className="text-xl font-medium text-gray-800">Friday July 29, 2022</h1>
          </div>
          <h3 className="text-gray-700">
            <span className="font-bold text-lg">19</span> out of{' '}
            <span className="font-bold text-lg">36</span> items reviewed
          </h3>
        </header>
        <div className="p-10 bg-gray-50 flex-gow"></div>
      </main>
    </DashboardChrome>
  );
};

export default MonitoringDayView;
