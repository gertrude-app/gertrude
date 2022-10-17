import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  type: 'success' | 'error' | 'info' | 'warning';
  heading: string;
  message: string;
};

const ContactStatusMessage: React.FC<Props> = ({ className, type, heading, message }) => {
  let icon = ``;
  const color = { bg: ``, text: ``, iconBg: ``, iconText: `` };

  switch (type) {
    case `success`:
      icon = `check`;
      color.bg = `bg-green-300`;
      color.text = `text-green-800`;
      color.iconText = `text-green-500`;
      break;
    case `warning`:
      icon = `exclamation`;
      color.bg = `bg-yellow-300`;
      color.text = `text-yellow-800`;
      color.iconText = `text-yellow-500`;
      break;
    case `error`:
      icon = `exclamation-triangle`;
      color.bg = `bg-red-300`;
      color.text = `text-red-800`;
      color.iconText = `text-red-500`;
      break;
    case `info`:
      icon = `info`;
      color.bg = `bg-indigo-300`;
      color.text = `text-indigo-800`;
      color.iconText = `text-indigo-500`;
      break;
  }

  return (
    <div className={cx(`${color.bg} bg-opacity-50 p-4 rounded-xl flex`, className)}>
      <div className="w-8 flex items-center flex-col">
        <i className={`fa-solid fa-${icon} ${color.iconText} text-xl`} />
      </div>
      <div className="ml-3">
        <h3 className={`${color.text} font-medium`}>{heading}</h3>
        <p className={`${color.text} text-opacity-70 text-sm mt-1`}>{message}</p>
      </div>
    </div>
  );
};

export default ContactStatusMessage;
