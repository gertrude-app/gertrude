import React from 'react';
import { MenuBarSized } from '../MenuBar';

const Connecting: React.FC = () => (
  <MenuBarSized className="flex flex-col justify-center items-center">
    <div className="bg-gradient-to-br from-indigo-500 to-fuchsia-500 w-16 h-16 rounded-full flex justify-center items-center">
      <i className="fas fa-spinner text-white text-3xl animate-spin" />
    </div>
  </MenuBarSized>
);

export default Connecting;
