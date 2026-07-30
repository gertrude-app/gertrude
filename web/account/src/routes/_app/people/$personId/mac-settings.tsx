import { createFileRoute } from '@tanstack/react-router';
import React from 'react';
import PersonSettingsComingSoonPage from '#/components/pages/person-settings/PersonSettingsComingSoonPage';

const MacSettingsRoute: React.FC = () => <PersonSettingsComingSoonPage platform="mac" />;

export const Route = createFileRoute(`/_app/people/$personId/mac-settings`)({
  component: MacSettingsRoute,
});
