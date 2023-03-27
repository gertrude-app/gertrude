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
  secondaryButton?: {
    action: string | (() => unknown);
    text: string;
    icon: string;
  };
  violet?: boolean;
};

const EmptyState: React.FC<Props> = ({
  className,
  heading,
  secondaryText,
  buttonText,
  action,
  secondaryButton,
  icon,
  violet = false,
}) => (
  <div
    className={cx(
      `flex flex-col justify-center items-center p-6 sm:p-10 rounded-2xl shadow-inner`,
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
    <h2 className="text-xl font-bold mt-3 mb-2 text-center">{heading}</h2>
    <p className="text-gray-500 text-center">{secondaryText}</p>
    <div className="flex flex-col sm:flex-row sm:items-center justify-center items-stretch mt-6 w-full">
      {typeof action === `string` ? (
        <Button color="primary" type="link" to={action}>
          <i className="fa fa-plus mr-4" />
          {buttonText}
        </Button>
      ) : (
        <Button color="primary" type="button" onClick={action}>
          <i className="fa fa-plus mr-4" />
          {buttonText}
        </Button>
      )}
      {secondaryButton &&
        (typeof secondaryButton.action === `string` ? (
          <Button
            color="secondary"
            type="link"
            to={secondaryButton.action}
            className="sm:ml-4 mt-3 sm:mt-0"
          >
            <i className={`fa-solid fa-${secondaryButton.icon} mr-4`} />
            {secondaryButton.text}
          </Button>
        ) : (
          <Button
            color="secondary"
            type="button"
            onClick={secondaryButton.action}
            className="sm:ml-4 mt-3 sm:mt-0"
          >
            <i className={`fa-solid fa-${secondaryButton.icon} mr-4`} />
            {secondaryButton.text}
          </Button>
        ))}
    </div>
  </div>
);

export default EmptyState;
