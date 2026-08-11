import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import IosSettingsComingSoonPage from '#/components/pages/person-settings/IosSettingsComingSoonPage';

const IosSettingsRoute: React.FC = () => <IosSettingsComingSoonPage />;

export const Route = createFileRoute(`/_app/people/$personId/ios-settings`)({
  component: IosSettingsRoute,
});
