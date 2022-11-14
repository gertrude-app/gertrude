import React from 'react';
import cx from 'classnames';
import GradientIcon from '../GradientIcon';
import PillBadge from '../PillBadge';

type Props = {
  model: string;
  status: 'online' | 'offline';
  icon: 'desktop' | 'laptop';
  className?: string;
};

const UserDevice: React.FC<Props> = ({ model, status, icon, className }) => (
  <div
    className={cx(
      `border rounded-full p-2 pr-4 shadow bg-white duration-75 transition`,
      className,
    )}
  >
    <div className="flex justify-between items-center">
      <div className="flex items-center">
        <GradientIcon icon={icon} size="medium" className="mr-3" subtle />
        <h3 className="text-gray-500 text-lg font-medium">{model}</h3>
      </div>
      {status === `online` && (
        <>
          <PillBadge type="green" className="items-center hidden sm:flex">
            <li className="fa fa-circle mr-2 text-xs text-green-500" />
            online
          </PillBadge>
          <div className="block sm:hidden">
            <li className="fa fa-circle text-sm text-green-400 mr-2" />
          </div>
        </>
      )}
    </div>
  </div>
);

export default UserDevice;
