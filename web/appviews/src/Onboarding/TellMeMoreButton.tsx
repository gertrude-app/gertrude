import React from 'react';
import cx from 'classnames';

interface Props {
  onClick(): unknown;
  children: React.ReactNode;
  size?: `small` | `large`;
}

const TellMeMoreButton: React.FC<Props> = ({ onClick, children, size = `large` }) => (
  <button
    tabIndex={-1}
    onClick={onClick}
    className={cx(
      `font-medium text-violet-500 hover:bg-violet-100 rounded-xl transition-[background-color,transform] duration-200 active:scale-[97%] active:bg-violet-200`,
      size === `small` ? `py-0.5 px-2.5 mx-1` : `py-2 px-4 mx-2`,
    )}
  >
    <i className="fa-solid far fa-circle-question mr-2" />
    <span>{children}</span>
  </button>
);

export default TellMeMoreButton;
