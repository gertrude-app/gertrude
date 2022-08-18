import React from 'react';
import ActivityDay from '@shared/dashboard/UserActivity/Day';

const MonitoringOverview: React.FC = () => (
  <main className="bg-gray-50">
    <h1 className="font-lato mb-4 sm:mb-7 ml-3 lg:ml-1 text-2xl sm:text-3xl text-gray-700">
      Little Jimmy's activity:
    </h1>
    <div className="space-y-10 p-2">
      <ActivityDay to="/day-view" date={new Date()} numItems={233} numCompleted={0} />
      <ActivityDay to="/day-view" date={new Date()} numItems={156} numCompleted={67} />
      <ActivityDay to="/day-view" date={new Date()} numItems={253} numCompleted={253} />
      <ActivityDay to="/day-view" date={new Date()} numItems={311} numCompleted={311} />
      <ActivityDay to="/day-view" date={new Date()} numItems={70} numCompleted={70} />
    </div>
  </main>
);

export default MonitoringOverview;
