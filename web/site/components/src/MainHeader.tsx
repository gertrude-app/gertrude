import React from 'react';
import { Button, Logo } from '@shared/components';
import { SmallScreenLoginDropdown } from './SmallScreenLoginDropdown';

const MainHeader: React.FC = () => (
  <header className="flex justify-between items-center px-5 sm:px-8 py-6 bg-violet-500">
    <a href="/">
      <Logo type="inverted" />
    </a>
    <SmallScreenLoginDropdown className="block sm:hidden" />
    <div className="hidden sm:flex space-x-3">
      <Button
        type="external"
        href="https://dash.gertrude.app"
        color="secondary-on-violet-bg"
      >
        Log in
      </Button>
      <Button
        type="external"
        href="https://dash.gertrude.app/signup"
        color="primary-on-violet-bg"
      >
        Sign up
      </Button>
    </div>
  </header>
);

export default MainHeader;
