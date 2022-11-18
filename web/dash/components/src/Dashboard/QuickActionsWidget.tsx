import React from 'react';
import { timeOfDay } from '@dash/datetime';
import Action from '../Action';
import DashboardWidget from './DashboardWidget';

type Props = {
  className?: string;
  createKeychain: () => unknown;
  date?: Date;
};

const QuickActionsWidget: React.FC<Props> = ({
  className,
  createKeychain,
  date = new Date(),
}) => (
  <DashboardWidget className={className}>
    <h1 className="text-2xl font-extrabold my-2 ml-2">Good {timeOfDay(date)}!</h1>
    <p className="mb-4 ml-2 text-gray-500">
      Here are some quick actions you may find useful:
    </p>
    <QuickAction name="Create new user" icon="user-plus" action="/users/new" />
    <QuickAction name="Create new keychain" icon="key" action={createKeychain} />
    <QuickAction
      name="View documentation"
      icon="book"
      action="https://gertrude.app/docs"
    />
    <QuickAction
      name="Submit support request"
      icon="life-ring"
      action="https://gertrude.app/contact"
    />
  </DashboardWidget>
);

export default QuickActionsWidget;

interface QuickActionProps {
  name: string;
  icon: string;
  action: string | (() => unknown);
}

const QuickAction: React.FC<QuickActionProps> = ({ name, icon, action }) => (
  <Action
    {...(typeof action === `string`
      ? { type: `link`, to: action }
      : { type: `button`, onClick: action })}
    className="p-4 flex items-center odd:bg-gray-50 rounded-xl hover:bg-violet-50 transition duration-100 focus:outline focus:outline-violet-200"
  >
    <div className="flex justify-center items-center text-white bg-gradient-to-br from-indigo-500 to-fuchsia-500 w-10 h-10 rounded-lg shrink-0">
      <i className={`fa-solid fa-${icon}`} />
    </div>
    <h2 className="font-medium leading-5 ml-3 text-lg text-gray-800">{name}</h2>
  </Action>
);
