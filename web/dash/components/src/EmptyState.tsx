import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';

type Props = {
  className?: string;
  heading: string;
  secondaryText: string;
  icon: string;
  buttonText: string;
  action: string | (() => unknown);
  violet?: boolean;
};

const EmptyState: React.FC<Props> = ({
  className,
  heading,
  secondaryText,
  buttonText,
  action,
  icon,
  violet = false,
}) => (
  <div
    className={cx(
      `flex flex-col justify-center items-center p-10 rounded-2xl shadow-inner`,
      violet ? `bg-violet-100` : `bg-gray-100`,
      className,
    )}
  >
    <i
      className={cx(
        `fa-solid fa-${icon} text-6xl`,
        violet ? `text-violet-300` : `text-gray-300`,
      )}
    />
    <h2 className="text-xl font-bold mt-3 mb-2">{heading}</h2>
    <p className="text-gray-500">{secondaryText}</p>
    {typeof action === `string` ? (
      <Button color="primary" type="link" to={action} className="mt-6" small>
        <i className="fa fa-plus mr-4" />
        {buttonText}
      </Button>
    ) : (
      <Button color="primary" type="button" onClick={action} className="mt-6" small>
        <i className="fa fa-plus mr-4" />
        {buttonText}
      </Button>
    )}
  </div>
);

export default EmptyState;
