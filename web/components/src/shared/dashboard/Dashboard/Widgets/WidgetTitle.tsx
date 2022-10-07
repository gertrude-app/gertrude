import React from 'react';
import cx from 'classnames';
import GradientIcon from '../../GradientIcon/GradientIcon';

type Props = {
  text: string;
  icon: React.ComponentProps<typeof GradientIcon>['icon'];
  className?: string;
};

const WidgetTitle: React.FC<Props> = ({ icon, text, className }) => (
  <h3
    className={cx(
      `flex items-center px-1.5 pb-2 mb-4 border-b border-violet-400/20`,
      className,
    )}
  >
    <GradientIcon icon={icon} size="small" className="mr-2" />
    <span className="font-bold text-lg text-gray-900 antialiased">{text}</span>
  </h3>
);

export default WidgetTitle;
