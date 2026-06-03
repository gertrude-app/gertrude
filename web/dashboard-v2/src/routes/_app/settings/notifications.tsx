import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import CardContainer from '#/components/CardContainer';

const NotificationSettingsPage: React.FC = () => (
  <div className="flex flex-col gap-4 mt-4">
    <CardContainer>
      <h2 className="text-xl font-medium">Methods</h2>
      <p className="text-stone-600">
        Verified ways that Gertrude can notify you for child requests and events.
      </p>
    </CardContainer>
    <CardContainer>
      <h2 className="text-xl font-medium">Notifications</h2>
      <p className="text-stone-600">
        Custom notifications for different types of events using one of your verified
        methods.
      </p>
    </CardContainer>
  </div>
);

export const Route = createFileRoute(`/_app/settings/notifications`)({
  component: NotificationSettingsPage,
});
