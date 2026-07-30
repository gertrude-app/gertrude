import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import PersonSettingsComingSoonPage from '#/components/pages/person-settings/PersonSettingsComingSoonPage';

const IosSettingsRoute: React.FC = () => <PersonSettingsComingSoonPage platform="ios" />;

export const Route = createFileRoute(`/_app/people/$personId/ios-settings`)({
  component: IosSettingsRoute,
});
