import Button from '@shared/Button';
import Logo from '@shared/Logo';
import React from 'react';

const MainHeader: React.FC = () => (
  <header className="flex justify-between items-center px-5 sm:px-8 py-6 bg-violet-500">
    <Logo type="inverted" />
    <div className="flex space-x-3">
      <Button
        className="hidden sm:flex"
        type="external"
        href="https://dash.gertrude.app/login"
        color="secondary-violet"
        small
      >
        Log in
      </Button>
      <Button
        type="external"
        href="https://dash.gertrude.app/signup"
        color="primary-white"
        small
      >
        Sign up
      </Button>
    </div>
  </header>
);

export default MainHeader;
