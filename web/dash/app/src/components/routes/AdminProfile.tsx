import React, { useEffect } from 'react';
import { ApiErrorMessage, Loading, Profile } from '@dash/components';
import { isUnsaved } from '@dash/utils';
import { capitalize } from '@shared/string';
import { notNullish, typesafe } from '@shared/ts-utils';
import type { GetAdmin } from '@dash/types';
import type { QueryProps, State } from '../../redux/store';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  cancelAdminEntityDelete,
  fetchProfileData,
  startAdminEntityDelete,
  deleteNotification,
  deleteNotificationMethod,
  notificationChanged,
  upsertNotification,
  notificationCreated,
  newNotificationMethodEvent,
  createPendingNotificationMethod,
  confirmPendingNotificationMethod,
  createBillingPortalSession,
} from '../../redux/slice-admin';
import { isDirty, Query, Req } from '../../redux/helpers';

const AdminProfile: React.FC = () => {
  const dispatch = useDispatch();
  const [query, shouldFetch] = useSelector(queryProps(dispatch));

  useEffect(() => {
    shouldFetch && dispatch(fetchProfileData());
  }, [dispatch, shouldFetch]);

  if (query.state === `shouldFetch` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed` || query.state === `entityDeleted`) {
    return <ApiErrorMessage error={query.state === `failed` ? query.error : void 0} />;
  }

  return <Profile {...query.props} />;
};

export default AdminProfile;

export const queryProps: QueryProps<typeof Profile> = (dispatch) => (state) => {
  const request = state.admin.profileRequest;
  if (request.state !== `succeeded`) {
    return [Req.toUnresolvedQuery(request), request.state !== `failed`];
  }

  const admin = state.admin;
  const methods = admin.notificationMethods;
  const deleteNotificationId = admin.deleting.notification;
  const deleteMethodId = admin.deleting.notificationMethod;
  const notificationProps = makeGetNotificationProps(admin);

  return [
    Query.resolve({
      email: request.payload.email,
      status: request.payload.subscriptionStatus,
      billingPortalRequest: state.admin.billingPortalRequest,
      manageSubscription: () => dispatch(createBillingPortalSession()),
      methods: typesafe.objectValues(methods).map((method) => ({
        id: method.value.id,
        method: methodSimpleType(method),
        value: methodPrimaryValue(method),
        deletable: methodDeletable(method, admin.notifications, request.payload.email),
      })),
      notifications: typesafe
        .objectValues(admin.notifications)
        .map(notificationProps)
        .filter(notNullish),
      deleteNotification: {
        id: deleteNotificationId,
        start: (id) => dispatch(startAdminEntityDelete({ type: `notification`, id })),
        confirm: () => dispatch(deleteNotification(deleteNotificationId ?? ``)),
        cancel: () => dispatch(cancelAdminEntityDelete(`notification`)),
      },
      deleteMethod: {
        id: deleteMethodId,
        start: (id) =>
          dispatch(startAdminEntityDelete({ type: `notificationMethod`, id })),
        confirm: () => dispatch(deleteNotificationMethod(deleteMethodId ?? ``)),
        cancel: () => dispatch(cancelAdminEntityDelete(`notificationMethod`)),
      },
      pendingMethod: admin.pendingNotificationMethod,
      createNotification: () => dispatch(notificationCreated()),
      saveNotification: (id) => dispatch(upsertNotification(id)),
      updateNotification: (update) => dispatch(notificationChanged(update)),
      newMethodEventHandler: (event) => {
        switch (event.type) {
          case `send_code_clicked`:
            return dispatch(createPendingNotificationMethod());
          case `verify_code_clicked`:
            return dispatch(confirmPendingNotificationMethod());
          default:
            return dispatch(newNotificationMethodEvent(event));
        }
      },
    }),
    false,
  ];
};

// helpers

function methodSimpleType(
  method: GetAdmin.VerifiedNotificationMethod,
): 'email' | 'slack' | 'text' {
  switch (method.type) {
    case `VerifiedEmailMethod`:
      return `email`;
    case `VerifiedSlackMethod`:
      return `slack`;
    case `VerifiedTextMethod`:
      return `text`;
  }
}

function methodPrimaryValue(method: GetAdmin.VerifiedNotificationMethod): string {
  switch (method.type) {
    case `VerifiedEmailMethod`:
      return method.value.email.toLowerCase();
    case `VerifiedSlackMethod`:
      return `#` + method.value.channelName.replace(/^#/, ``);
    case `VerifiedTextMethod`: {
      const number = method.value.phoneNumber;
      if (number.match(/^\d{10}$/)) {
        return `(${number.slice(0, 3)}) ${number.slice(3, 6)}-${number.slice(6, 10)}`;
      }
      return number;
    }
  }
}

function methodDeletable(
  method: GetAdmin.VerifiedNotificationMethod,
  notifications: State['admin']['notifications'],
  adminEmail: EmailAddress,
): any {
  const methodBeingUsed = typesafe
    .objectValues(notifications)
    .some((notification) => notification.original.methodId === method.value.id);

  if (methodBeingUsed) {
    return false;
  }

  return method.type !== `VerifiedEmailMethod` || method.value.email !== adminEmail;
}

function makeGetNotificationProps(
  state: State['admin'],
): (
  editable: State['admin']['notifications'][string],
) => React.ComponentProps<typeof Profile>['notifications'][0] | null {
  return (editable) => {
    const { id, ...notification } = editable.draft;
    const methods = state.notificationMethods;
    const method = methods[notification.methodId];
    if (!method) return null; // should never happen...
    return {
      id,
      trigger: notification.trigger,
      selectedMethod: method,
      saveButtonDisabled: isUnsaved(id)
        ? false
        : !isDirty(editable) || state.saveNotificationRequests[id]?.state === `ongoing`,
      methodOptions: typesafe.objectValues(methods).map((method) => ({
        display: `${capitalize(methodSimpleType(method))} ${methodPrimaryValue(method)}`,
        value: method.value.id,
      })),
      editing: editable.editing,
    };
  };
}
