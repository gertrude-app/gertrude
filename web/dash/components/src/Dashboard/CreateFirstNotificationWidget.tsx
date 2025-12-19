import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import DashboardWidget from './DashboardWidget';

interface Props {
  className?: string;
}

const CreateFirstNotificationWidget: React.FC<Props> = ({ className }) => (
  <DashboardWidget className={cx(className)}>
    <div className=" flex flex-col h-full">
      <div className="flex-grow mb-8">
        <h1 className="text-2xl font-extrabold my-2 ml-2">
          Create your first notification!
        </h1>
        <p className="ml-2 text-slate-500 flex-grow">
          Gertrude can notify you with a text, email, or Slack when one of your children
          needs a website unblocked, or would like the filter temporarily suspended.
        </p>
      </div>
      <div className="py-4 sm:py-5 px-3 sm:px-4 -mb-3 sm:-mb-4 -mx-3 sm:-mx-4 bg-slate-50 rounded-b-3xl">
        <Button type="link" to="/settings" color="primary">
          Create a notification
        </Button>
      </div>
    </div>
  </DashboardWidget>
);

export default CreateFirstNotificationWidget;
