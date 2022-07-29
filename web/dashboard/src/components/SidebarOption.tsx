import React from 'react';
import { Link } from 'react-router-dom';

interface Props {
  icon: string;
  children: string;
  expanded: boolean;
  to: string;
}

const SidebarOption: React.FC<Props> = ({ icon, children, expanded, to }) => {
  const selected = location.pathname === to;
  return (
    <Link
      to={to}
      className={`flex justify-start items-center bg-violet-500 bg-opacity-0 cursor-pointer transition duration-75 select-none w-80 ${
        selected ? `bg-opacity-20` : `hover:bg-opacity-10`
      } ${expanded ? `rounded-xl py-3 px-5 my-3 ` : `py-[1.4em] pl-[1.65em]`}`}
    >
      <i
        className={`fa fa-${icon} mr-4 text-2xl  ${
          selected
            ? `bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text text-transparent`
            : `text-violet-300 text-opacity-40`
        }`}
      />
      <h2
        className={`text-white text-xl text-opacity-60 font-bold ${
          expanded ? `block` : `hidden`
        }`}
      >
        {children}
      </h2>
    </Link>
  );
};

export default SidebarOption;
