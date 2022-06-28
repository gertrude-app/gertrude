import Button from '@shared/Button';
import React from 'react';
import Logo from './Logo';

const MainHeader: React.FC = () => {
  return (
    <header className="flex justify-between items-center px-5 sm:px-8 py-6 border-b-2 border-white border-opacity-20 bg-violet-500">
      <Logo />
      <div>
        <Button type="button" onClick={() => {}} color="primary-white" small>
          Sign up
        </Button>
      </div>
    </header>
  );
};

export default MainHeader;
