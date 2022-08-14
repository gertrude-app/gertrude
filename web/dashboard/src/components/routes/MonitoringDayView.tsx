import React from 'react';
import { Link } from 'react-router-dom';
import Button from '@shared/Button';
import KeystrokesViewer from '@shared/dashboard/Monitoring/KeystrokesViewer';
import ScreenshotViewer from '@shared/dashboard/Monitoring/ScreenshotViewer';

const MonitoringDayView: React.FC = () => (
  <main className="flex flex-col min-h-screen">
    <header className="flex flex-col sm:flex-row itesm-center justify-between py-4 px-6 border-b-2 bg-gray-50">
      <div className="flex items-center">
        <Link
          to="/monitoring"
          className="flex items-center mr-6 text-gray-500 hover:text-gray-600 transition duration-75 text-lg"
        >
          <i className="fa fa-chevron-left text-lg mr-2" /> Back
        </Link>
        <h1 className="text-xl font-medium text-gray-800">Friday July 29, 2022</h1>
      </div>
      <h3 className="text-gray-700 self-end sm:self-center mt-2 sm:mt-0">
        <span className="font-bold text-lg">19</span> out of{` `}
        <span className="font-bold text-lg">36</span> items reviewed
      </h3>
    </header>
    <div className="px-0 md:px-5 lg:px-10 py-5 md:py-10 bg-gray-200 md:bg-gray-50 flex-grow space-y-8 flex flex-col">
      <KeystrokesViewer
        strokes={`Dearest diggital diiary,\nsSorry it's been so long. I'll try to right more.\nUntil tomorrow.`}
        date={new Date()}
        application="Notes"
      />
      <KeystrokesViewer
        strokes={`Dear digital diary,\nhow have you been? I've beeeen alright. More later.`}
        date={new Date()}
        application="Notes"
      />
      <ScreenshotViewer image={`https://placekitten.com/1200/600`} date={new Date()} />
      <ScreenshotViewer image={`https://placekitten.com/1400/700`} date={new Date()} />
      <ScreenshotViewer image={`https://placekitten.com/800/600`} date={new Date()} />
      <KeystrokesViewer
        strokes={`cute cat pictures`}
        date={new Date()}
        application="Safari"
      />
      <Button
        className="self-center"
        type="button"
        onClick={() => {}}
        color="primary-violet"
      >
        Approve all
      </Button>
    </div>
  </main>
);

export default MonitoringDayView;
