import React from 'react';
import NotificationMethod from '../NotificationMethod/NotificationMethod';

const NotificationMethodsMenu: React.FC = () => (
  <ul className="mt-5 border-red-500">
    <NotificationMethod method="email" address="me@example.com" />
    <NotificationMethod method="slack" channel="#Gertrude" />
    <NotificationMethod method="email" address="you@example.xom" />
    <NotificationMethod method="text" number="(123) 456-7890" />
  </ul>
);

export default NotificationMethodsMenu;
