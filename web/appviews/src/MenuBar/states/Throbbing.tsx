import { Loading } from '@shared/components';
import React from 'react';
import { MenuBarSized } from '../MenuBar';

const Throbbing: React.FC = () => (
  <MenuBarSized className="flex flex-col justify-center items-center">
    <Loading />
  </MenuBarSized>
);

export default Throbbing;
