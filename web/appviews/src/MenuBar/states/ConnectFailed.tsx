import React from 'react';
import { MenuBarSized } from '../MenuBar';

interface Props {
  error: string;
}

const ConnectFailed: React.FC<Props> = ({ error }) => {
  return (
    <MenuBarSized className="p-3">
      <h1>Error</h1>
      <p className="text-red-500">{error}</p>
      <div className="flex gap-4">
        <button className="border bg-white">Try again (primary)</button>
        <button className="border bg-white">Get help (secondary)</button>
      </div>
    </MenuBarSized>
  );
};

export default ConnectFailed;
