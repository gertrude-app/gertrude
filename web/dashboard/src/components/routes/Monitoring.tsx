import MonitoredDay from '@shared/dashboard/MonitoredDay';
import React from 'react';
import Chrome from '../Chrome';

const Monitoring: React.FC = () => {
  return (
    <Chrome>
      <main className="px-2 sm:px-4 md:px-6 lg:py-10 py-10 bg-gray-50">
        <h1 className="font-lato mb-4 sm:mb-7 ml-3 lg:ml-1 text-2xl sm:text-3xl text-gray-700">
          Little Jimmy's activity:
        </h1>
        <div className="space-y-10 p-2">
          <MonitoredDay
            to="/day-view"
            date={new Date()}
            numItems={233}
            numCompleted={0}
          />
          <MonitoredDay
            to="/day-view"
            date={new Date()}
            numItems={156}
            numCompleted={67}
          />
          <MonitoredDay
            to="/day-view"
            date={new Date()}
            numItems={253}
            numCompleted={253}
          />
          <MonitoredDay
            to="/day-view"
            date={new Date()}
            numItems={311}
            numCompleted={311}
          />
          <MonitoredDay
            to="/day-view"
            date={new Date()}
            numItems={70}
            numCompleted={70}
          />
        </div>
      </main>
    </Chrome>
  );
};

export default Monitoring;
