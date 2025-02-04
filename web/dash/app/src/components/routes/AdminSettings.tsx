import { v4 as uuid } from 'uuid';
import React, { useReducer, useState } from 'react';
import { ApiErrorMessage, Loading, Settings } from '@dash/components';
import { capitalize } from '@shared/string';
import { notNullish, typesafe } from '@shared/ts-utils';
import { Result } from '@dash/types';
import { parseE164, prettyE164 } from '@dash/utils';
import type { NewMethod } from '@dash/components/src/Settings/Settings';
import type { VerifiedNotificationMethod } from '@dash/types';
import type { State } from '../../reducers/admin-reducer';
import { isDirty, Req } from '../../lib/helpers';
import { useQuery, Key, useMutation, useConfirmableDelete } from '../../hooks';
import Current from '../../environment';
import ReqState from '../../lib/ReqState';
import reducer, { initialState } from '../../reducers/admin-reducer';

const AdminSettings: React.FC = () => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const [newMethodId, setNewMethodId] = useState<NewMethod | undefined>(undefined);

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
      onSuccess: ({ methodId }) => {
        setNewMethodId({ id: methodId, confirmed: false });
        dispatch(PendingMethod.createSucceeded(methodId));
      },
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
      onSuccess: () => {
        dispatch(PendingMethod.confirmSucceeded);
        if (newMethodId) {
          setNewMethodId({ id: newMethodId.id, confirmed: true });
        }
      },
      onError: () => dispatch(PendingMethod.confirmFailed),
      toast: `confirm:pending-notification-method`,
      invalidating: [Key.admin],
    },
  );

  if (query.isPending) {
    return <Loading />;
  }

  if (query.isError) {
    return <ApiErrorMessage error={query.error} />;
  }

  const admin = query.data;
  const notificationProps = makeNotificationProps(
    state,
    saveNotification.isPending,
    admin.hasAdminChild,
  );

  return (
    <Settings
      newMethodId={newMethodId}
      setNewMethodId={setNewMethodId}
      email={admin.email}
      status={admin.subscriptionStatus}
      monthlyPriceInDollars={admin.monthlyPriceInDollars}
      billingPortalRequest={ReqState.fromMutation(getStripeUrl)}
      methods={typesafe.objectValues(state.notificationMethods).map((method) => ({
        id: method.id,
        method: method.config.case,
        value: methodPrimaryValue(method),
        deletable: methodDeletable(method, state.notifications, admin.email),
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
      return prettyE164(method.config.phoneNumber);
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
  showSecurityEventOption: boolean,
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
      showSecurityEventOption,
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
