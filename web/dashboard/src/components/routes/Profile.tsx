import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import Profile from '@shared/dashboard/Profile';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  cancelEntityDelete,
  fetchProfileData,
  startEntityDelete,
  deleteNotification,
  deleteNotificationMethod,
} from '../../redux/slice-admin';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';
import { notNullish, Query } from '../../redux/helpers';
import { Trigger } from '../../graphqlTypes';
import { VerifiedNotificationMethod, Notification } from '../../types/Admin';
import { QueryProps } from '../../redux/store';

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
  const deleteNotificationId = state.admin.pendingDeletionNotificationId;
  const deleteMethodId = state.admin.pendingDeletionVerifiedNotificationMethodId;

  return Query.succeed({
    email: request.payload.email,
    status: request.payload.subscriptionStatus,
    methods: typesafe
      .objectValues(state.admin.verifiedNotificationMethods)
      .map((method) => ({
        id: method.id,
        method: method.data.type,
        value: verifiedMethodPrimaryValue(method),
        deletable: methodDeletable(
          method,
          state.admin.notifications,
          request.payload.email,
        ),
      })),
    notifications: typesafe
      .objectValues(state.admin.notifications)
      .map((n) => {
        const method = methods[n.methodId];
        if (!method) return null;
        return {
          id: n.id,
          when:
            n.trigger === Trigger.suspendFilterRequestSubmitted
              ? (`suspension requests` as const)
              : (`unlock requests` as const),
          method: method.data.type,
          value: verifiedMethodPrimaryValue(method),
        };
      })
      .filter(notNullish),
    deleteNotification: {
      id: deleteNotificationId,
      start: (id) => dispatch(startEntityDelete({ type: `Notification`, id })),
      confirm: () =>
        deleteNotificationId && dispatch(deleteNotification(deleteNotificationId)),
      cancel: () => dispatch(cancelEntityDelete(`Notification`)),
    },
    deleteMethod: {
      id: deleteMethodId,
      start: (id) =>
        dispatch(startEntityDelete({ type: `VerifiedNotificationMethod`, id })),
      confirm: () => deleteMethodId && dispatch(deleteNotificationMethod(deleteMethodId)),
      cancel: () => dispatch(cancelEntityDelete(`VerifiedNotificationMethod`)),
    },
  });
};

function verifiedMethodPrimaryValue(method: VerifiedNotificationMethod): string {
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
  method: VerifiedNotificationMethod,
  notifications: Record<UUID, Notification>,
  adminEmail: EmailAddress,
): any {
  const methodBeingUsed = typesafe
    .objectValues(notifications)
    .some((notification) => notification.methodId === method.id);

  if (methodBeingUsed) {
    return false;
  }

  return method.data.type !== `email` || method.data.email !== adminEmail;
}
