import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import Profile from '@dashboard/Profile';
import { AdminNotificationMethod } from '@dashboard/types/Admin';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  cancelEntityDelete,
  fetchProfileData,
  startEntityDelete,
  deleteNotification,
  deleteNotificationMethod,
  notificationChanged,
  updateNotification,
} from '../../redux/slice-admin';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';
import { isDirty, notNullish, Query } from '../../redux/helpers';
import { QueryProps, State } from '../../redux/store';
import { capitalize } from '../shared/lib/string';

const ProfileContainer: React.FC = () => {
  const dispatch = useDispatch();
  const adminId = useSelector((state) => state.auth.admin?.id ?? ``);
  const query = useSelector(queryProps(dispatch));

  const reqState = query.state;
  useEffect(() => {
    reqState === `idle` && dispatch(fetchProfileData(adminId));
  }, [dispatch, adminId, reqState]);

  if (query.state === `idle` || query.state === `ongoing`) {
    return <Loading />;
  }

  if (query.state === `failed`) {
    return <ApiErrorMessage error={query.error} />;
  }

  return <Profile {...query.props} />;
};

export default ProfileContainer;

// helpers

export const queryProps: QueryProps<typeof Profile> = (dispatch) => (state) => {
  const request = state.admin.profileRequest;
  if (request.state !== `succeeded`) {
    return request;
  }

  const methods = state.admin.verifiedNotificationMethods;
  const deleteNotificationId = state.admin.deleting.notification;
  const deleteMethodId = state.admin.deleting.notificationMethod;
  const saveNotifications = state.admin.saveNotificationRequests;

  return Query.succeed({
    email: request.payload.email,
    status: request.payload.subscriptionStatus,
    updateNotification: (update) => dispatch(notificationChanged(update)),
    methods: typesafe
      .objectValues(state.admin.verifiedNotificationMethods)
      .map((method) => ({
        id: method.id,
        method: method.data.type,
        value: methodPrimaryValue(method),
        deletable: methodDeletable(
          method,
          state.admin.notifications,
          request.payload.email,
        ),
      })),
    notifications: typesafe
      .objectValues(state.admin.notifications)
      .map((editable) => {
        const { id, ...notification } = editable.draft;
        const method = methods[notification.methodId];
        if (!method) return null;
        return {
          id,
          trigger: notification.trigger,
          selectedMethod: method,
          saveButtonDisabled:
            !isDirty(editable) || saveNotifications[id]?.state === `ongoing`,
          methodOptions: typesafe.objectValues(methods).map((method) => ({
            display: `${capitalize(method.data.type)} ${methodPrimaryValue(method)}`,
            value: method.id,
          })),
          editing: editable.editing,
        };
      })
      .filter(notNullish),
    saveNotification: (id) => dispatch(updateNotification(id)),
    deleteNotification: {
      id: deleteNotificationId,
      start: (id) => dispatch(startEntityDelete({ type: `notification`, id })),
      confirm: () =>
        deleteNotificationId && dispatch(deleteNotification(deleteNotificationId)),
      cancel: () => dispatch(cancelEntityDelete(`notification`)),
    },
    deleteMethod: {
      id: deleteMethodId,
      start: (id) => dispatch(startEntityDelete({ type: `notificationMethod`, id })),
      confirm: () => deleteMethodId && dispatch(deleteNotificationMethod(deleteMethodId)),
      cancel: () => dispatch(cancelEntityDelete(`notificationMethod`)),
    },
  });
};

function methodPrimaryValue(method: AdminNotificationMethod): string {
  switch (method.data.type) {
    case `email`:
      return method.data.email;
    case `slack`:
      return method.data.channelName;
    case `text`:
      return method.data.phoneNumber;
  }
}

function methodDeletable(
  method: AdminNotificationMethod,
  notifications: State['admin']['notifications'],
  adminEmail: EmailAddress,
): any {
  const methodBeingUsed = typesafe
    .objectValues(notifications)
    .some((notification) => notification.original.methodId === method.id);

  if (methodBeingUsed) {
    return false;
  }

  return method.data.type !== `email` || method.data.email !== adminEmail;
}
