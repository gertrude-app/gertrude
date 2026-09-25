import { useQueryClient } from '@tanstack/react-query';
import { createFileRoute, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type {
  ClaimAccountIOSDevice,
  GetAccountIOSClaimData,
} from '@shared/pairql/src/account';
import ConnectIosAppCodePage from '#/components/pages/devices/ConnectIosAppCodePage';
import ConnectIosAppPage from '#/components/pages/devices/ConnectIosAppPage';
import ConnectIosAppResultPage from '#/components/pages/devices/ConnectIosAppResultPage';
import SupervisionSetupPage from '#/components/pages/devices/SupervisionSetupPage';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

type Flow = GetAccountIOSClaimData.Input[`flow`];
type Stage =
  | `result`
  | `plan`
  | `computerRequired`
  | `download`
  | `launch`
  | `connect`
  | `supervise`
  | `checking`
  | `finishOnDevice`
  | `complete`;

const appDetails: Record<Flow, { name: string; icon: string }> = {
  blockerConnect: { name: `Gertrude Blocker`, icon: `/gertrude-app-icons/blocker.webp` },
  blockerSupervise: {
    name: `Gertrude Blocker`,
    icon: `/gertrude-app-icons/blocker.webp`,
  },
  podcasts: { name: `Gertrude Podcasts`, icon: `/gertrude-app-icons/podcasts.webp` },
  music: { name: `Gertrude Music`, icon: `/gertrude-app-icons/music.webp` },
};

const ConnectRoute: React.FC = () => {
  const { flow, code } = Route.useParams();
  return <ConnectFlow key={`${flow}/${code}`} flow={flow} code={code} />;
};

const ConnectFlow: React.FC<{ flow: string; code: string }> = ({ flow, code }) => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const validFlow = flow in appDetails ? (flow as Flow) : undefined;
  const validCode = /^\d{6}$/.test(code) ? Number(code) : undefined;
  const queryKey = Key.iosClaim(flow, code);
  const query = useQuery(
    queryKey,
    () => liveClient.getAccountIOSClaimData({ flow: flow as Flow, code: Number(code) }),
    {
      enabled: validFlow !== undefined && validCode !== undefined,
      retry: false,
      refetchInterval: ({ state }) =>
        flow === `blockerSupervise` && state.data?.assignment ? 5000 : false,
    },
  );
  const claim = useMutation(liveClient.claimAccountIOSDevice, {
    invalidating: [queryKey, Key.devices, Key.people],
  });
  const [stage, setStage] = React.useState<Stage>();
  const [downloaded, setDownloaded] = React.useState(false);
  const [platform, setPlatform] = React.useState<`mac` | `windows`>();
  const [copied, setCopied] = React.useState(false);
  const data = claim.data ?? query.data;
  const assignment = query.data?.assignment ?? claim.data?.assignment;
  const status = query.data?.assignment?.supervisionStatus;
  const device = data && {
    type: data.deviceType === `iPad` ? (`iPad` as const) : (`iPhone` as const),
    modelName: data.modelName,
    modelIdentifier: data.modelIdentifier,
  };
  const goToDevices = (): void => void navigate({ to: `/devices` });
  const goToSettings = (): void => {
    if (assignment)
      void navigate({
        to: `/people/$personId/ios-settings`,
        params: { personId: assignment.personId },
        search: {
          section:
            validFlow === `podcasts`
              ? `podcasts`
              : validFlow === `music`
                ? `music`
                : `blocker`,
        },
      });
  };

  React.useEffect(() => {
    if (flow !== `blockerSupervise`) return;
    if (status === `complete`) setStage(`complete`);
    else if (status === `supervised`) setStage(`finishOnDevice`);
  }, [flow, status]);

  if (!validFlow || validCode === undefined) {
    return (
      <ConnectIosAppCodePage
        appName="Gertrude"
        appIconUrl="/gertrude-app-icons/blocker.webp"
        state="invalid"
        onBack={goToDevices}
      />
    );
  }

  const app = appDetails[validFlow];
  if (!data && query.isError) {
    const errorState = query.error.userMessage?.toLowerCase().includes(`expired`)
      ? (`expired` as const)
      : query.error.type === `notFound`
        ? (`invalid` as const)
        : (`error` as const);
    return (
      <ConnectIosAppCodePage
        appName={app.name}
        appIconUrl={app.icon}
        state={errorState}
        onBack={goToDevices}
        onRetry={() => void query.refetch()}
      />
    );
  }
  if (!data || !device) {
    return (
      <ConnectIosAppCodePage appName={app.name} appIconUrl={app.icon} state="checking" />
    );
  }

  if (!assignment) {
    const submit = async (
      selection:
        | { type: `existing`; id: string }
        | { type: `new`; name: string; relationship: `child` | `peer` | `self` },
    ): Promise<void> => {
      const person: ClaimAccountIOSDevice.Input[`person`] =
        selection.type === `existing`
          ? { case: `existing`, id: selection.id }
          : { case: `new`, name: selection.name, relationship: selection.relationship };
      try {
        const output = await claim.mutateAsync({
          flow: validFlow,
          code: validCode,
          person,
        });
        queryClient.setQueryData(queryKey.segments, output);
        setStage(`result`);
      } catch {
        return;
      }
    };
    return (
      <ConnectIosAppPage
        flow={validFlow}
        device={device}
        people={data.people}
        selfRelationshipUnavailable={data.people.some(
          (person) => person.relationship === `self`,
        )}
        submitting={claim.isPending}
        error={
          claim.isError
            ? (claim.error.userMessage ??
              `Couldn't connect this device. Please try again.`)
            : undefined
        }
        onSubmit={(selection) => void submit(selection)}
        onCancel={goToDevices}
      />
    );
  }

  if (validFlow !== `blockerSupervise`) {
    if (validFlow === `blockerConnect`) {
      return (
        <ConnectIosAppResultPage
          flow="blockerConnect"
          device={device}
          personName={assignment.personName}
          onPrimary={goToSettings}
        />
      );
    }
    if (validFlow === `podcasts`) {
      const subscription = assignment.amSubscription;
      const access =
        subscription?.case === `unpaid` || subscription?.case === `legacyExpired`
          ? `lapsed`
          : subscription?.case === `legacyGrandfathered`
            ? `ending`
            : subscription?.case === `amTrial` || subscription?.case === `fullTrial`
              ? `trial`
              : `active`;
      return (
        <ConnectIosAppResultPage
          flow="podcasts"
          device={device}
          personName={assignment.personName}
          access={access}
          accessEndsAt={
            subscription?.case === `legacyGrandfathered`
              ? new Date(subscription.accessEndsAt).toLocaleDateString()
              : undefined
          }
          onPrimary={
            access === `lapsed`
              ? () => void navigate({ to: `/settings/billing` })
              : goToSettings
          }
          onSecondary={access === `lapsed` ? goToSettings : undefined}
        />
      );
    }
    const access =
      assignment.musicSubscription?.case === `unavailable`
        ? `unavailable`
        : assignment.musicSubscription?.case === `trial`
          ? `trial`
          : assignment.musicSubscription?.case === `active`
            ? `active`
            : `trialReady`;
    return (
      <ConnectIosAppResultPage
        flow="music"
        device={device}
        personName={assignment.personName}
        access={access}
        onPrimary={
          access === `unavailable`
            ? () => void navigate({ to: `/settings/billing` })
            : goToSettings
        }
        onSecondary={access === `unavailable` ? goToSettings : undefined}
      />
    );
  }

  const onContinue = (): void => {
    if (assignment.requiresPayment) setStage(`plan`);
    else
      setStage(
        /iPhone|iPad|Android/i.test(navigator.userAgent)
          ? `computerRequired`
          : `download`,
      );
  };
  const currentStage = stage ?? `result`;
  if (currentStage === `result`) {
    return (
      <ConnectIosAppResultPage
        flow="blockerSupervise"
        device={device}
        personName={assignment.personName}
        nextStep={assignment.requiresPayment ? `plan` : `computer`}
        onPrimary={onContinue}
        onSecondary={goToDevices}
      />
    );
  }
  const common = {
    device,
    personName: assignment.personName,
    onFinishLater: goToDevices,
  };
  switch (currentStage) {
    case `plan`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="plan"
          onPrimary={() => {
            sessionStorage.setItem(`pairingReturnPath`, `/connect/${validFlow}/${code}`);
            void navigate({ to: `/settings/billing` });
          }}
        />
      );
    case `computerRequired`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="computerRequired"
          onPrimary={goToDevices}
          onThisIsComputer={() => setStage(`download`)}
        />
      );
    case `download`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="download"
          downloaded={downloaded}
          platform={platform}
          onDownload={(selected) => {
            setPlatform(selected);
            setDownloaded(true);
            const iframe = document.createElement(`iframe`);
            iframe.hidden = true;
            iframe.src = `${apiEndpoint}/download-supervision-app/${code}/platform/${selected}`;
            document.body.appendChild(iframe);
            setTimeout(() => iframe.remove(), 5000);
          }}
          onPrimary={() => setStage(`launch`)}
        />
      );
    case `launch`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="launch"
          onPrimary={() => setStage(`connect`)}
        />
      );
    case `connect`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="connect"
          code={code}
          copied={copied}
          onCopy={() => {
            void navigator.clipboard.writeText(code).then(() => setCopied(true));
          }}
          onPrimary={() => setStage(`supervise`)}
        />
      );
    case `supervise`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="supervise"
          onPrimary={() => {
            setStage(`checking`);
            void query.refetch();
          }}
        />
      );
    case `checking`:
      return (
        <SupervisionSetupPage {...common} stage="checking" onPrimary={() => undefined} />
      );
    case `finishOnDevice`:
      return (
        <SupervisionSetupPage
          {...common}
          stage="finishOnDevice"
          onPrimary={() => {
            setStage(`checking`);
            void query.refetch();
          }}
        />
      );
    case `complete`:
      return (
        <SupervisionSetupPage {...common} stage="complete" onPrimary={goToSettings} />
      );
  }
};

export const Route = createFileRoute(`/_app/connect/$flow/$code`)({
  component: ConnectRoute,
});
