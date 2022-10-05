import React from 'react';
import cx from 'classnames';
import DashboardWidget from '../DashboardWidget';
import { timeOfDay } from '../../lib/dates';

type Props = {
  className?: string;
};

const QuickActionsWidget: React.FC<Props> = ({ className }) => (
  <DashboardWidget className={className}>
    <h1 className="text-xl font-bold mt-2 ml-2">Good {timeOfDay(new Date())}!</h1>
    <p className="mb-4 ml-2 text-gray-500">
      Here's some quick actions you may find useful:
    </p>
    <QuickAction
      name={`Create new user`}
      icon={`user-plus`}
      href={`/users/new`}
      className={``}
    />
    <QuickAction
      name={`Create new keychain`}
      icon={`key`}
      href={`/keychains/id-123`}
      className={``}
    />
    <QuickAction name={`View documentation`} icon={`book`} href={`#`} className={``} />
    <QuickAction
      name={`Submit support request`}
      icon={`life-ring`}
      href={`#`}
      className={``}
    />
  </DashboardWidget>
);

export default QuickActionsWidget;

interface QuickActionProps {
  name: string;
  icon: string;
  href: string;
  className?: string;
}

const QuickAction: React.FC<QuickActionProps> = ({ name, icon, href, className }) => {
  return (
    <a
      href={href}
      className={cx(
        `p-4 flex items-center odd:bg-gray-50 rounded-xl hover:bg-violet-50 transition duration-100 focus:outline focus:outline-violet-200`,
        className,
      )}
    >
      <div className="flex justify-center items-center text-white bg-gradient-to-br from-indigo-500 to-fuchsia-500 w-10 h-10 rounded-lg shrink-0">
        <i className={`fa-solid fa-${icon}`} />
      </div>
      <h2 className="font-medium ml-3 text-lg text-gray-800">{name}</h2>
    </a>
  );
};
