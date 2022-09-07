import React from 'react';
import cx from 'classnames';

type Props = {
  title: string;
  description: string;
  selected: boolean;
  onClick(): void;
};

const KeyScopeRadioOption: React.FC<Props> = ({
  title,
  description,
  selected,
  onClick,
}) => (
  <button
    className="flex w-full text-left hover:bg-gray-50 transition duration-100 rounded-xl outline-none focus:ring-2 focus:ring-violet-400"
    onClick={onClick}
  >
    <div
      className={cx(
        `w-12 flex flex-shrink-0 justify-center items-center`,
        selected ? `` : ``,
      )}
    >
      <div
        className={cx(
          `rounded-full flex justify-center items-center text-white [transition:100ms]`,
          selected
            ? `border-none w-6 h-6 bg-gradient-to-br from-indigo-500 to-fuchsia-500`
            : `w-5 h-5 border-2 `,
        )}
      >
        <i className="fa-solid fa-check text-sm" />
      </div>
    </div>
    <div className="flex-grow p-3">
      <h3 className="font-bold">{title}</h3>
      <p className="w-fit text-gray-500">{description}</p>
    </div>
  </button>
);

export default KeyScopeRadioOption;
