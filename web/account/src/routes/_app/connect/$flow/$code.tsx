import { LoadingDots, toast } from '@gertrude/ui';
import { useQueryClient } from '@tanstack/react-query';
import { createFileRoute, redirect, useNavigate } from '@tanstack/react-router';
import React from 'react';
import type {
  ClaimAccountIOSDevice,
  GetAccountIOSClaimData,
} from '@shared/pairql/src/account';
import ConnectIosAppCodePage from '#/components/pages/devices/ConnectIosAppCodePage';
import ConnectIosAppPage from '#/components/pages/devices/ConnectIosAppPage';
import ConnectIosAppResultPage from '#/components/pages/devices/ConnectIosAppResultPage';
import SupervisionSetupPage from '#/components/pages/devices/SupervisionSetupPage';
import { podcastsSubscriptionRunway } from '#/components/person-settings/podcastsSubscriptionRunway';
import { planGateLabel } from '#/lib/billing';
import { apiEndpoint, liveClient } from '#/pairql/client';
import { Key } from '#/pairql/keys';
import { useMutation } from '#/pairql/mutation';
import { useQuery } from '#/pairql/query';

type Flow = GetAccountIOSClaimData.Input[`flow`];
type ManualStage =
  | `result`
  | `plan`
  | `computerRequired`
  | `download`
  | `launch`
  | `connect`
  | `supervise`;

const appDetails: Record<Flow, { name: string; icon: string }> = {
  blockerConnect: { name: `Gertrude Blocker`, icon: `/gertrude-app-icons/blocker.webp` },
  blockerSupervise: {
    name: `Gertrude Blocker`,
    icon: `/gertrude-app-icons/blocker.webp`,
  },
  podcasts: { name: `Gertrude Podcasts`, icon: `/gertrude-app-icons/podcasts.webp` },
  music: { name: `Gertrude Music`, icon: `/gertrude-app-icons/music.webp` },
};

type ConnectSearch = {
  checkout?: `success` | `canceled`;
  session_id?: string;
  step?: `download`;
};

const computerStage = (): ManualStage =>
  /iPhone|iPad|Android/i.test(navigator.userAgent) ||
  (/Macintosh/i.test(navigator.userAgent) && navigator.maxTouchPoints > 1)
    ? `computerRequired`
    : `download`;

const ConnectRoute: React.FC = () => {
  const { flow, code } = Route.useParams();
  const { checkout, step } = Route.useSearch();
  const { checkoutError } = Route.useLoaderData();
  return (
    <ConnectFlow
      key={`${flow}/${code}`}
      flow={flow}
      code={code}
      initialStage={
        step === `download`
          ? computerStage()
          : checkout === `canceled` || checkoutError
            ? `plan`
            : undefined
      }
      checkoutCanceled={checkout === `canceled`}
      checkoutError={checkoutError}
    />
  );
};

const ConnectFlow: React.FC<{
  flow: string;
  code: string;
  initialStage?: ManualStage;
  checkoutCanceled: boolean;
  checkoutError?: string;
}> = ({ flow, code, initialStage, checkoutCanceled, checkoutError }) => {
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
      refetchInterval: ({ state }) => {
        const assignment = state.data?.assignment;
        if (
          flow === `blockerSupervise` &&
          assignment &&
          assignment.supervisionStatus !== `complete`
        )
          return 5000;
        if (flow === `music` && assignment && assignment.musicSubscription === undefined)
          return 3000;
        return false;
      },
    },
  );
  const claim = useMutation(liveClient.claimAccountIOSDevice, {
    invalidating: [queryKey, Key.devices, Key.people, Key.accountSetup],
  });
  const startCheckout = useMutation(liveClient.startAccountCheckout);
  const openPortal = useMutation(liveClient.openAccountBillingPortal);
  const [stage, setStage] = React.useState<ManualStage | undefined>(initialStage);
  const [downloaded, setDownloaded] = React.useState(false);
  const [platform, setPlatform] = React.useState<`mac` | `windows`>();
  const [copied, setCopied] = React.useState(false);
  const data = claim.data ?? query.data;
  const assignment = query.data?.assignment ?? claim.data?.assignment;
  const device = data && {
    type: data.deviceType === `iPad` ? (`iPad` as const) : (`iPhone` as const),
    modelName: data.modelName,
    modelIdentifier: data.modelIdentifier,
  };
  const goToDevices = (): void => void navigate({ to: `/devices` });
  const goToBilling = (): void => {
    if (!validFlow) return;
    sessionStorage.setItem(`pairingReturnPath`, `/connect/${validFlow}/${code}`);
    void navigate({ to: `/settings/billing` });
  };
  const goToSettings = (): void => {
    if (assignment)
      void navigate({
        to: `/people/$personId/ios-settings`,
        params: { personId: assignment.personId },
        hash: validFlow === `music` ? undefined : assignment.deviceId,
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
      const runway = subscription && podcastsSubscriptionRunway(subscription);
      const access =
        runway?.tier === `lapsed`
          ? `lapsed`
          : runway?.tier === `expiring`
            ? `ending`
            : runway?.trialDaysRemaining !== undefined
              ? `trial`
              : `active`;
      return (
        <ConnectIosAppResultPage
          flow="podcasts"
          device={device}
          personName={assignment.personName}
          access={access}
          accessEndsAt={runway?.accessEndsAt}
          onPrimary={access === `lapsed` ? goToBilling : goToSettings}
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
        onPrimary={access === `unavailable` ? goToBilling : goToSettings}
        onSecondary={access === `unavailable` ? goToSettings : undefined}
      />
    );
  }

  const onContinue = (): void => {
    setStage(assignment.requiresPayment ? `plan` : computerStage());
  };
  const flowPath = `/connect/${validFlow}/${code}`;
  const handlePlanAction = async (): Promise<void> => {
    const action = assignment.paymentAction;
    try {
      switch (action?.case) {
        case `startCheckout`:
        case `reactivateViaCheckout`: {
          const output = await startCheckout.mutateAsync({
            tier: action.tier,
            successPath: `${flowPath}?checkout=success`,
            cancelPath: `${flowPath}?checkout=canceled`,
            associatedIosDeviceId: assignment.deviceId,
          });
          window.location.assign(output.url);
          return;
        }
        case `openBillingPortal`: {
          const output = await openPortal.mutateAsync({
            returnPath: flowPath,
            configuration: action.config,
          });
          window.location.assign(output.url);
          return;
        }
        default:
          goToBilling();
      }
    } catch {
      return;
    }
  };
  const planError = startCheckout.isError
    ? (startCheckout.error.userMessage ?? `Couldn’t open checkout. Please try again.`)
    : openPortal.isError
      ? (openPortal.error.userMessage ??
        `Couldn’t open the billing portal. Please try again.`)
      : checkoutError;
  const requestedStage = stage ?? `result`;
  const currentStage =
    assignment.supervisionStatus === `complete`
      ? `complete`
      : assignment.supervisionStatus === `supervised`
        ? assignment.requiresPayment
          ? `plan`
          : `finishOnDevice`
        : assignment.requiresPayment && requestedStage !== `result`
          ? `plan`
          : requestedStage;
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
          actionLabel={
            assignment.paymentAction && planGateLabel(assignment.paymentAction)
          }
          working={
            startCheckout.isPending ||
            startCheckout.isSuccess ||
            openPortal.isPending ||
            openPortal.isSuccess
          }
          checkoutCanceled={checkoutCanceled}
          error={planError}
          onPrimary={() => void handlePlanAction()}
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
    case `finishOnDevice`:
      return (
        <SupervisionSetupPage
          {...common}
          stage={currentStage}
          checking={query.isFetching}
          error={
            query.isError && !query.isFetching
              ? (query.error.userMessage ??
                `We couldn’t check the device. Check your connection and try again.`)
              : undefined
          }
          onPrimary={() => void query.refetch()}
        />
      );
    case `complete`:
      return (
        <SupervisionSetupPage {...common} stage="complete" onPrimary={goToSettings} />
      );
  }
};

export const Route = createFileRoute(`/_app/connect/$flow/$code`)({
  validateSearch: (search): ConnectSearch => ({
    checkout:
      search[`checkout`] === `success` || search[`checkout`] === `canceled`
        ? search[`checkout`]
        : undefined,
    session_id:
      typeof search[`session_id`] === `string` ? search[`session_id`] : undefined,
    step: search[`step`] === `download` ? `download` : undefined,
  }),
  loaderDeps: ({ search }) => ({
    checkout: search.checkout,
    sessionId: search.session_id,
  }),
  loader: async ({ params, deps: { checkout, sessionId }, context, cause }) => {
    if (cause === `preload` || !checkout || !sessionId) {
      return { checkoutError: undefined };
    }

    if (checkout === `canceled`) {
      void liveClient.handleAccountCheckoutCancel({ stripeCheckoutSessionId: sessionId });
      throw redirect({
        to: `/connect/$flow/$code`,
        params,
        search: { checkout: `canceled` },
        replace: true,
      });
    }

    const result = await liveClient.handleAccountCheckoutSuccess({
      stripeCheckoutSessionId: sessionId,
    });
    if (result.error) {
      return {
        checkoutError:
          result.error.userMessage ??
          `We couldn’t confirm your subscription. Check your connection and try again.`,
      };
    }

    await context.queryClient.invalidateQueries({
      queryKey: Key.iosClaim(params.flow, params.code).segments,
    });
    toast.success(`Your Gertrude subscription is ready`);
    throw redirect({
      to: `/connect/$flow/$code`,
      params,
      search: { step: `download` },
      replace: true,
    });
  },
  pendingComponent: () => (
    <div className="flex min-h-screen items-center justify-center bg-stone-50">
      <LoadingDots />
    </div>
  ),
  component: ConnectRoute,
});
