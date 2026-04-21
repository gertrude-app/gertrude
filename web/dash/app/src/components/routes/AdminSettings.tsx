import { ApiErrorMessage, Loading, Settings } from '@dash/components';
import { Result } from '@shared/pairql';
import { parseE164, prettyE164 } from '@shared/phone-numbers';
import { capitalize } from '@shared/string';
import { notNullish, typesafe } from '@shared/ts-utils';
import React, { useReducer, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import type { State } from '../../reducers/admin-reducer';
import type { NewMethod } from '@dash/components';
import type { VerifiedNotificationMethod } from '@dash/types';
import Current from '../../environment';
import { Key, useConfirmableDelete, useMutation, useQuery } from '../../hooks';
import ReqState from '../../lib/ReqState';
import { Req, isDirty } from '../../lib/helpers';
import reducer, { initialState } from '../../reducers/admin-reducer';

const AdminSettings: React.FC = () => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const [newMethodId, setNewMethodId] = useState<NewMethod | undefined>(undefined);
  const [searchParams] = useSearchParams();
  const requestedTier = searchParams.get(`plan`) as `full` | `light` | null;

  const query = useQuery(Key.accountOwner, Current.api.getAccountOwner, {
    onReceive: (accountOwner) => dispatch({ type: `receivedAccountOwner`, accountOwner }),
  });

  const getStripeUrl = useMutation((tier: `full` | `light` | null) =>
    Current.api.stripeUrl({
      successPath: `/checkout-success`,
      cancelPath: `/checkout-cancel`,
      tier: tier ?? undefined,
    }),
  );

  const deleteNotification = useConfirmableDelete(`parentNotification`, {
    invalidating: [Key.accountOwner],
  });

  const deleteMethod = useConfirmableDelete(`parentVerifiedNotificationMethod`, {
    invalidating: [Key.accountOwner],
  });

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

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const accountOwner = query.data;
  const notificationProps = makeNotificationProps(state, saveNotification.isPending);

  return (
    <Settings
      newMethodId={newMethodId}
      setNewMethodId={setNewMethodId}
      email={accountOwner.email}
      plan={accountOwner.plan}
      billingPortalRequest={ReqState.fromMutation(getStripeUrl)}
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
      requestedTier={requestedTier}
      manageSubscription={() => getStripeUrl.mutate(requestedTier)}
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
