import React from 'react';
import { Loading } from '@shared/components';
import { MenuBarSized } from '../MenuBar';

const Connecting: React.FC = () => (
  <MenuBarSized className="flex flex-col justify-center items-center">
    <Loading />
  </MenuBarSized>
);

export default Connecting;
