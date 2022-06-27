import React from 'react';
import ButtonPrimary from './ButtonPrimary';
import Logo from './Logo';

const MainHeader: React.FC = () => {
  return (
    <header className="flex justify-between items-center px-5 sm:px-8 py-6 border-b-2 border-white border-opacity-20 bg-violet-500">
      <Logo />
      <div>
        <ButtonPrimary type="primary" onClick={() => alert(`April fools`)}>
          Sign up
        </ButtonPrimary>
      </div>
    </header>
  );
};

export default MainHeader;
