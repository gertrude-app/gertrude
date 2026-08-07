import {
  ApiErrorMessage,
  Loading,
  MacOverview,
  type MacOverviewSection,
  type SectionFact,
} from '@dash/components';
import React from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import type { Child, PlainTime } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';

const MacRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const navigate = useNavigate();
  const childQuery = useQuery(Key.child(userId), () => Current.api.getChild(userId));

  const addDevice = useMutation((childId: UUID) =>
    Current.api.macAppConnectionCode({ childId }),
  );
  const startTrial = useMutation(() => Current.api.startFullTrial());

  if (childQuery.isError) {
    return <ApiErrorMessage error={childQuery.error} />;
  }

  if (!childQuery.data) {
    return <Loading />;
  }

  const child = childQuery.data;
  const hasMac = child.computers.length > 0;

  const monitoring: MacOverviewSection = {
    glyph: `binoculars`,
    title: `Monitoring`,
    facts: monitoringFacts(child),
    manageLabel: hasMonitoring(child) ? `Manage monitoring` : `Set up monitoring`,
    onManage: () => navigate(`./monitoring`),
  };

  const filtering: MacOverviewSection = {
    glyph: `lock`,
    title: `Internet filtering`,
    facts: filteringFacts(child),
    manageLabel: `Manage filtering`,
    onManage: () => navigate(`./filtering`),
  };

  const apps: MacOverviewSection = {
    glyph: `layer-group`,
    title: `Apps`,
    facts: appsFacts(child),
    manageLabel: (child.blockedApps?.length ?? 0) === 0 ? `Pick apps` : `Manage apps`,
    onManage: () => navigate(`./apps`),
  };

  return (
    <MacOverview
      personName={child.name}
      hasMac={hasMac}
      monitoring={monitoring}
      filtering={filtering}
      apps={apps}
      startAddDevice={() => addDevice.mutate(userId)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      onStartTrial={() => startTrial.mutate(undefined)}
    />
  );
};

export default MacRoute;

function hasMonitoring(child: Child): boolean {
  return child.keyloggingEnabled || child.screenshotsEnabled;
}

function monitoringFacts(child: Child): SectionFact[] {
  const facts: SectionFact[] = [];
  facts.push(
    child.keyloggingEnabled
      ? { text: `Keylogging is on` }
      : { text: `Keylogging is off`, muted: true },
  );
  facts.push(
    child.screenshotsEnabled
      ? { text: `Screenshots every ${formatFrequency(child.screenshotsFrequency)}` }
      : { text: `Screenshots are off`, muted: true },
  );
  return facts;
}

function filteringFacts(child: Child): SectionFact[] {
  const facts: SectionFact[] = [];

  if (child.downtime) {
    facts.push({
      text: `Downtime nightly, ${formatTime(child.downtime.start)} – ${formatTime(child.downtime.end)}`,
    });
  } else {
    facts.push({ text: `No downtime configured`, muted: true });
  }

  const numKeychains = child.keychains.length;
  const numKeys = child.keychains.reduce((sum, k) => sum + k.numKeys, 0);
  if (numKeychains === 0) {
    facts.push({ text: `No keychains attached`, muted: true });
  } else {
    facts.push({
      text: `${pluralize(numKeychains, `keychain`)} attached, ${pluralize(numKeys, `key`)}`,
    });
  }

  const numGroups = child.alwaysBlockedGroupIds.length;
  const numCustom = child.customAlwaysBlockedRules.length;
  facts.push(alwaysBlockedFact(numGroups, numCustom));

  return facts;
}

function alwaysBlockedFact(numGroups: number, numCustom: number): SectionFact {
  if (numGroups === 0 && numCustom === 0) {
    return { text: `Nothing always-blocked`, muted: true };
  }
  if (numCustom === 0) {
    return {
      text: `${pluralize(numGroups, `always-blocked category`, `always-blocked categories`)}`,
    };
  }
  if (numGroups === 0) {
    return { text: `${pluralize(numCustom, `custom always-blocked rule`)}` };
  }
  return {
    text: `${pluralize(numGroups, `always-blocked category`, `always-blocked categories`)}, ${numCustom} custom`,
  };
}

function appsFacts(child: Child): SectionFact[] {
  const numBlocked = child.blockedApps?.length ?? 0;
  if (numBlocked === 0) {
    return [{ text: `No apps blocked`, muted: true }];
  }
  return [{ text: pluralize(numBlocked, `app`) + ` blocked` }];
}

function formatFrequency(seconds: number): string {
  if (seconds % 60 === 0 && seconds >= 60) {
    const minutes = seconds / 60;
    return pluralize(minutes, `minute`);
  }
  return pluralize(seconds, `second`);
}

function formatTime({ hour, minute }: PlainTime): string {
  const pm = hour >= 12;
  const h = hour % 12 || 12;
  const m = minute.toString().padStart(2, `0`);
  return `${h}:${m}${pm ? `pm` : `am`}`;
}

function pluralize(n: number, singular: string, plural?: string): string {
  return `${n} ${n === 1 ? singular : (plural ?? `${singular}s`)}`;
}
