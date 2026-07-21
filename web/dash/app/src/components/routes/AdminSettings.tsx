import { ApiErrorMessage, Loading, Settings } from '@dash/components';
import { Result } from '@shared/pairql';
import { parseE164, prettyE164 } from '@shared/phone-numbers';
import { capitalize } from '@shared/string';
import { notNullish, typesafe } from '@shared/ts-utils';
import React, { useEffect, useReducer, useState } from 'react';
import toast from 'react-hot-toast';
import { v4 as uuid } from 'uuid';
import type { State } from '../../reducers/admin-reducer';
import type { NewMethod } from '@dash/components';
import type {
  SubscriptionPanelAction,
  SubscriptionTier,
  VerifiedNotificationMethod,
} from '@dash/types';
import Current from '../../environment';
import { Key, useConfirmableDelete, useMutation, useQuery } from '../../hooks';
import { Req, isDirty } from '../../lib/helpers';
import reducer, { initialState } from '../../reducers/admin-reducer';

const AdminSettings: React.FC = () => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const [newMethodId, setNewMethodId] = useState<NewMethod | undefined>(undefined);
  const [pendingPanelAction, setPendingPanelAction] = useState<
    SubscriptionPanelAction | undefined
  >(undefined);

  const query = useQuery(Key.accountOwner, Current.api.getAccountOwner, {
    onReceive: (accountOwner) => dispatch({ type: `receivedAccountOwner`, accountOwner }),
  });

  const panelQuery = useQuery(Key.subscriptionPanel, () =>
    Current.api.getSubscriptionPanel(undefined),
  );

  const startCheckout = useMutation(
    ({ tier }: { tier: SubscriptionTier }) =>
      Current.api.startCheckoutSession({
        tier,
        successPath: `/checkout-success`,
        cancelPath: `/checkout-cancel`,
      }),
    {
      onError: () => {
        setPendingPanelAction(undefined);
        toast.error(`Failed to open Stripe. Please try again.`);
      },
    },
  );

  const openBillingPortal = useMutation(
    ({ configuration }: { configuration: `lightTier` | `mediumTier` | `default` }) =>
      Current.api.openBillingPortal({
        returnPath: `/settings`,
        configuration,
      }),
    {
      onError: () => {
        setPendingPanelAction(undefined);
        toast.error(`Failed to open Stripe. Please try again.`);
      },
    },
  );

  const changeSubscriptionTier = useMutation(
    ({ to }: { to: SubscriptionTier }) => Current.api.changeSubscriptionTier({ to }),
    {
      invalidating: [Key.subscriptionPanel],
      onSuccess: () => {
        setPendingPanelAction(undefined);
        toast.success(`Plan updated!`);
      },
      onError: () => {
        setPendingPanelAction(undefined);
        toast.error(`Failed to update plan. Please try again.`);
      },
    },
  );

  const startFullTrial = useMutation(() => Current.api.startFullTrial(undefined), {
    invalidating: [Key.subscriptionPanel],
    onSuccess: () => {
      setPendingPanelAction(undefined);
      toast.success(`Free trial started!`);
    },
    onError: () => {
      setPendingPanelAction(undefined);
      toast.error(`Failed to start trial. Please try again.`);
    },
  });

  useEffect(() => {
    if (startCheckout.isSuccess) {
      window.location.href = startCheckout.data.url;
    }
  }, [startCheckout.isSuccess, startCheckout.data?.url]);

  useEffect(() => {
    if (openBillingPortal.isSuccess) {
      window.location.href = openBillingPortal.data.url;
    }
  }, [openBillingPortal.isSuccess, openBillingPortal.data?.url]);

  const deleteNotification = useConfirmableDelete(`parentNotification`, {
    invalidating: [Key.accountOwner],
  });

  const deleteMethod = useConfirmableDelete(`parentVerifiedNotificationMethod`, {
    invalidating: [Key.accountOwner],
  });

  const toggleDailyReviewEmail = useMutation(
    (enabled: boolean) => Current.api.setDailyReviewEmail({ enabled }),
    { invalidating: [Key.accountOwner] },
  );

  const saveNotification = useMutation(
    (id: UUID) => {
      const notification = state.notifications[id];
      if (!notification) return Result.resolveUnexpected(`1662407a`);
      return Current.api.saveNotification({
        id: notification.id,
        isNew: notification.isNew === true,
        methodId: notification.draft.methodId,
        trigger: notification.draft.trigger,
      });
    },
    { toast: `save:notification`, invalidating: [Key.accountOwner] },
  );

  const createPendingNotificationMethod = useMutation(
    () => {
      let method = state.pendingNotificationMethod;
      if (!method) return Result.resolveUnexpected(`bc7511bb`);
      if (method.case === `text`) {
        const e164 = parseE164(method.phoneNumber);
        if (!e164) return Result.resolveUnexpected(`707f8ce1`);
        method = structuredClone(method);
        method.phoneNumber = e164;
      }
      dispatch(PendingMethod.createStarted);
      return Current.api.createPendingNotificationMethod(method);
    },
    {
      onSuccess: ({ methodId, ntfyTopic }) => {
        setNewMethodId({ id: methodId, confirmed: false });
        dispatch(PendingMethod.createSucceeded(methodId, ntfyTopic));
      },
      onError: () => dispatch(PendingMethod.createFailed),
      toast: `create:pending-notification-method`,
      invalidating: [Key.accountOwner],
    },
  );

  const confirmPendingNotificationMethod = useMutation(
    () => {
      dispatch(PendingMethod.confirmStarted);
      return Current.api.confirmPendingNotificationMethod({
        id: Req.payload(state.pendingNotificationMethod?.sendCodeRequest) ?? ``,
        code: Number(state.pendingNotificationMethod?.confirmationCode),
      });
    },
    {
      onSuccess: () => {
        dispatch(PendingMethod.confirmSucceeded);
        if (newMethodId) {
          setNewMethodId({ id: newMethodId.id, confirmed: true });
        }
      },
      onError: () => dispatch(PendingMethod.confirmFailed),
      toast: `confirm:pending-notification-method`,
      invalidating: [Key.accountOwner],
    },
  );

  if (query.isPending || panelQuery.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  if (panelQuery.isError) {
    return <ApiErrorMessage error={panelQuery.error} />;
  }

  const accountOwner = query.data;
  const notificationProps = makeNotificationProps(state, saveNotification.isPending);

  const handleSubscriptionPanelAction = (action: SubscriptionPanelAction): void => {
    switch (action.case) {
      case `startCheckout`:
      case `reactivateViaCheckout`:
        setPendingPanelAction(action);
        startCheckout.mutate({ tier: action.tier });
        return;
      case `openBillingPortal`:
        setPendingPanelAction(action);
        openBillingPortal.mutate({ configuration: action.config });
        return;
      case `changeSubscriptionTier`:
        setPendingPanelAction(action);
        changeSubscriptionTier.mutate({ to: action.to });
        return;
      case `startFullTrial`:
        setPendingPanelAction(action);
        startFullTrial.mutate(undefined);
        return;
    }
  };

  return (
    <Settings
      newMethodId={newMethodId}
      setNewMethodId={setNewMethodId}
      email={accountOwner.email}
      dailyReviewEmail={accountOwner.dailyReviewEmail}
      setDailyReviewEmail={(enabled) => toggleDailyReviewEmail.mutate(enabled)}
      hasMacScreenshotUsers={accountOwner.hasMacScreenshotUsers}
      subscriptionPanel={panelQuery.data}
      onSubscriptionPanelAction={handleSubscriptionPanelAction}
      pendingSubscriptionPanelAction={pendingPanelAction}
      methods={typesafe.objectValues(state.notificationMethods).map((method) => ({
        id: method.id,
        method: method.config.case,
        value: methodPrimaryValue(method),
        deletable: methodDeletable(method, state.notifications, accountOwner.email),
        inUse: Object.values(state.notifications).some(
          (notif) => notif.original.methodId === method.id,
        ),
      }))}
      notifications={typesafe
        .objectValues(state.notifications)
        .map(notificationProps)
        .filter(notNullish)}
      deleteNotification={deleteNotification}
      deleteMethod={deleteMethod}
      pendingMethod={state.pendingNotificationMethod}
      updateNotification={(update) => dispatch({ type: `updateNotification`, update })}
      saveNotification={(id) => saveNotification.mutate(id)}
      createNotification={(methodId) =>
        dispatch({ type: `notificationCreated`, id: uuid(), methodId })
      }
      newMethodEventHandler={(event) => {
        switch (event.type) {
          case `sendCodeClicked`:
            return createPendingNotificationMethod.mutate(undefined);
          case `verifyCodeClicked`:
            return confirmPendingNotificationMethod.mutate(undefined);
          default:
            return dispatch({ type: `newNotificationMethodEvent`, event });
        }
      }}
    />
  );
};

export default AdminSettings;

// helpers

function methodPrimaryValue(method: VerifiedNotificationMethod): string {
  switch (method.config.case) {
    case `email`:
      return method.config.email.toLowerCase();
    case `slack`:
      return `#` + method.config.channelName.replace(/^#/, ``);
    case `text`: {
      return prettyE164(method.config.phoneNumber);
    }
    case `ntfy`: {
      const t = method.config.topic;
      return t.length > 15 ? `${t.slice(0, 12)}...` : t;
    }
  }
}

function methodDeletable(
  method: VerifiedNotificationMethod,
  notifications: State[`notifications`],
  adminEmail: string,
): boolean {
  const methodBeingUsed = typesafe
    .objectValues(notifications)
    .some((notification) => notification.original.methodId === method.id);

  if (methodBeingUsed) {
    return false;
  }

  return method.config.case !== `email` || method.config.email !== adminEmail;
}

function makeNotificationProps(
  state: State,
  savingNotification: boolean,
): (
  editable: State[`notifications`][number],
) => React.ComponentProps<typeof Settings>[`notifications`][0] | null {
  return (editable) => {
    const { id, ...notification } = editable.draft;
    const methods = state.notificationMethods;
    const method = methods[notification.methodId];
    if (!method) return null; // should never happen...
    return {
      id,
      trigger: notification.trigger,
      selectedMethod: method,
      saveButtonDisabled: editable.isNew
        ? false
        : !isDirty(editable) || savingNotification,
      methodOptions: typesafe.objectValues(methods).map((method) => ({
        display: `${capitalize(method.config.case)} ${methodPrimaryValue(method)}`,
        value: method.id,
      })),
      editing: editable.editing === true,
      isNew: editable.isNew === true,
    };
  };
}

const PendingMethod = {
  createStarted: {
    type: `newNotificationMethodEvent`,
    event: { type: `createPendingMethodStarted` },
  },
  createFailed: {
    type: `newNotificationMethodEvent`,
    event: { type: `createPendingMethodFailed` },
  },
  createSucceeded(methodId: UUID, ntfyTopic?: string) {
    return {
      type: `newNotificationMethodEvent`,
      event: { type: `createPendingMethodSucceeded`, methodId, ntfyTopic },
    } as const;
  },
  confirmStarted: {
    type: `newNotificationMethodEvent`,
    event: { type: `confirmPendingMethodStarted` },
  },
  confirmSucceeded: {
    type: `newNotificationMethodEvent`,
    event: { type: `confirmPendingMethodSucceeded` },
  },
  confirmFailed: {
    type: `newNotificationMethodEvent`,
    event: { type: `confirmPendingMethodFailed` },
  },
} as const;
