import React from 'react';

interface Props {
  children: React.ReactNode;
}

const UserInputText: React.FC<Props> = ({ children }) => (
  <span className="inline-block ml-px -translate-y-px font-mono bg-violet-100 py-[2px] px-3 rounded-lg border-b-2 border-violet-200 text-base font-medium">
    {children}
  </span>
);

export default UserInputText;
