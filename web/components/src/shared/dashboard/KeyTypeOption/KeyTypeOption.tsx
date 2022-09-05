import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  icon: string;
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
  <div
    className={cx(
      `relative border-2 rounded-xl p-4 cursor-pointer transition duration-100`,
      selected ? `border-violet-400 bg-violet-50` : `hover:bg-violet-50/50`,
      className,
    )}
    onClick={onClick}
  >
    {selected && (
      <i className="fa-solid fa-check absolute right-3 top-3 text-violet-500" />
    )}
    <h2 className="font-bold text-gray-700">
      <i
        className={cx(
          `fa-solid fa-${icon} mr-1 bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent`,
        )}
      />
      {` `}
      {title}
    </h2>
    <p className="text-sm text-gray-500 mt-1">{description}</p>
  </div>
);

export default KeyTypeOption;
