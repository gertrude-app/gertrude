import { v4 as uuid } from 'uuid';
import React, { useReducer } from 'react';
import { ApiErrorMessage, Loading, Settings } from '@dash/components';
import { capitalize } from '@shared/string';
import { notNullish, typesafe } from '@shared/ts-utils';
import { Result } from '@dash/types';
import type { VerifiedNotificationMethod } from '@dash/types';
import type { State } from '../../reducers/admin-reducer';
import { isDirty, Req } from '../../lib/helpers';
import { useQuery, Key, useMutation, useConfirmableDelete } from '../../hooks';
import Current from '../../environment';
import ReqState from '../../lib/ReqState';
import reducer, { initialState } from '../../reducers/admin-reducer';

const AdminSettings: React.FC = () => {
  const [state, dispatch] = useReducer(reducer, initialState);

  const query = useQuery(Key.admin, Current.api.getAdmin, {
    onReceive: (admin) => dispatch({ type: `receivedAdmin`, admin }),
  });

  const getStripeUrl = useMutation(Current.api.stripeUrl);

  const deleteNotification = useConfirmableDelete(`adminNotification`, {
    invalidating: [Key.admin],
  });

  const deleteMethod = useConfirmableDelete(`adminVerifiedNotificationMethod`, {
    invalidating: [Key.admin],
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
    { toast: `save:notification`, invalidating: [Key.admin] },
  );

  const createPendingNotificationMethod = useMutation(
    () => {
      const method = state.pendingNotificationMethod;
      if (!method) return Result.resolveUnexpected(`bc7511bb`);
      dispatch(PendingMethod.createStarted);
      return Current.api.createPendingNotificationMethod(method);
    },
    {
      onSuccess: ({ methodId }) => dispatch(PendingMethod.createSucceeded(methodId)),
      onError: () => dispatch(PendingMethod.createFailed),
      toast: `create:pending-notification-method`,
      invalidating: [Key.admin],
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
      onSuccess: () => dispatch(PendingMethod.confirmSucceeded),
      onError: () => dispatch(PendingMethod.confirmFailed),
      toast: `confirm:pending-notification-method`,
      invalidating: [Key.admin],
    },
  );

  const notificationProps = makeNotificationProps(state, saveNotification.isPending);

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  return (
    <Settings
      email={query.data.email}
      status={query.data.subscriptionStatus}
      billingPortalRequest={ReqState.fromMutation(getStripeUrl)}
      methods={typesafe.objectValues(state.notificationMethods).map((method) => ({
        id: method.id,
        method: method.config.case,
        value: methodPrimaryValue(method),
        deletable: methodDeletable(method, state.notifications, query.data.email),
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
      createNotification={() => dispatch({ type: `notificationCreated`, id: uuid() })}
      manageSubscription={() => getStripeUrl.mutate()}
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
      const number = method.config.phoneNumber;
      if (number.match(/^\d{10}$/)) {
        return `(${number.slice(0, 3)}) ${number.slice(3, 6)}-${number.slice(6, 10)}`;
      }
      return number;
    }
  }
}

function methodDeletable(
  method: VerifiedNotificationMethod,
  notifications: State['notifications'],
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
  editable: State['notifications'][number],
) => React.ComponentProps<typeof Settings>['notifications'][0] | null {
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
  createSucceeded(methodId: UUID) {
    return {
      type: `newNotificationMethodEvent`,
      event: { type: `createPendingMethodSucceeded`, methodId },
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
