import React from 'react';
import { Button, Logo } from '@shared/components';

const MainHeader: React.FC = () => (
  <header className="flex justify-between items-center px-5 sm:px-8 py-6 bg-violet-500">
    <a href="/">
      <Logo type="inverted" />
    </a>
    <div className="flex space-x-3">
      <Button
        className="hidden sm:flex"
        type="external"
        href="https://dash.gertrude.app/login"
        color="secondary-on-violet-bg"
        small
      >
        Log in
      </Button>
      <Button
        type="external"
        href="https://dash.gertrude.app/signup"
        color="primary-on-violet-bg"
        small
      >
        Sign up
      </Button>
    </div>
  </header>
);

export default MainHeader;
