import Logo from '@shared/Logo';
import React from 'react';
import SidebarOption from '../SidebarOption';

const App: React.FC = () => {
  return (
    <div className="min-h-screen flex">
      <nav className="bg-gradient-to-b from-violet-500 to-violet-700 p-4 -ml-80 lg:-ml-0 w-80">
        <Logo className="m-2 mb-10 mt-8" />
        <div className="mt-5 pb-4">
          <SidebarOption icon="home" selected={false}>
            Dashboard
          </SidebarOption>
          <SidebarOption icon="shield" selected={false}>
            Digital guardians
          </SidebarOption>
          <SidebarOption icon="users" selected={true}>
            Guarded users
          </SidebarOption>
          <SidebarOption icon="key" selected={false}>
            Keychains
          </SidebarOption>
        </div>
        <div className="border-t-4 border-white border-opacity-10 pt-4">
          <SidebarOption icon="user" selected={false}>
            Profile
          </SidebarOption>
          <SidebarOption icon="cog" selected={false}>
            Settings
          </SidebarOption>
        </div>
      </nav>
      <div className="h-screen flex justify-center items-center text-2xl font-mono font-extralight text-gray-200 flex-grow">
        <h1 className="text-5xl -rotate-45">stuff</h1>
      </div>
    </div>
  );
};

export default App;
