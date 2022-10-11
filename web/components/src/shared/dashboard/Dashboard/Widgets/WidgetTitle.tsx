import React from 'react';
import cx from 'classnames';
import GradientIcon from '../../GradientIcon/GradientIcon';

type Props = {
  text: string;
  icon: React.ComponentProps<typeof GradientIcon>['icon'];
  className?: string;
};

const WidgetTitle: React.FC<Props> = ({ icon, text, className }) => (
  <h3 className={cx(`flex items-center mb-3 sm:mb-4`, className)}>
    <GradientIcon icon={icon} size="medium" className="mr-1 scale-75" />
    <span className="font-extrabold text-2xl">{text}</span>
  </h3>
);

export default WidgetTitle;
