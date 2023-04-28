import React from 'react';
import cx from 'classnames';
import type { IconType } from '../GradientIcon';
import GradientIcon from '../GradientIcon';

type Props = {
  className?: string;
  icon: IconType;
  selected: boolean;
  onClick(): void;
  title: string;
  description: string;
};

const KeyTypeOption: React.FC<Props> = ({
  className,
  icon,
  selected,
  onClick,
  title,
  description,
}) => (
  <button
    className={cx(
      `relative flex flex-col justify-start text-left border-2 rounded-xl p-4 cursor-pointer transition duration-100 outline-none focus:ring-violet-300 ring-2 ring-transparent ring-offset-2`,
      selected ? `border-violet-400 bg-violet-50` : `hover:bg-violet-50/50`,
      className,
    )}
    onClick={onClick}
  >
    {selected && (
      <i className="fa-solid fa-check absolute right-3 top-3 text-violet-500" />
    )}
    <h2 className="font-bold text-slate-700">
      <GradientIcon icon={icon} size="small" className="mr-1" />
      {` `}
      {title}
    </h2>
    <p className="text-sm text-slate-500 mt-1">{description}</p>
  </button>
);

export default KeyTypeOption;
