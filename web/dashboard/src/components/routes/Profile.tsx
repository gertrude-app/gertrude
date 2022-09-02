import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import Profile from '@shared/dashboard/Profile';
import { useDispatch, useSelector } from '../../redux/hooks';
import {
  cancelEntityDelete,
  fetchProfileData,
  startEntityDelete,
  deleteNotification,
} from '../../redux/slice-admin';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';
import { notNullish } from '../../redux/helpers';
import { Trigger } from '../../graphqlTypes';
import { VerifiedNotificationMethod } from '../../types/Admin';

const ProfileContainer: React.FC = () => {
  const dispatch = useDispatch();
  const { adminId, request, methods, notifications, deleteNotificationId } = useSelector(
    (state) => ({
      adminId: state.auth.admin?.id ?? ``,
      request: state.admin.profileRequest,
      methods: state.admin.verifiedNotificationMethods,
      notifications: typesafe.objectValues(state.admin.notifications),
      deleteNotificationId: state.admin.pendingDeletionNotificationId,
    }),
  );

  const reqState = request.state;

  useEffect(() => {
    reqState === `idle` && dispatch(fetchProfileData(adminId));
  }, [dispatch, adminId, reqState]);

  if (request.state === `idle` || request.state === `ongoing`) {
    return <Loading />;
  }

  if (request.state === `failed`) {
    return <ApiErrorMessage error={request.error} />;
  }

  const admin = request.payload;
  return (
    <Profile
      email={admin.email}
      status={admin.subscriptionStatus}
      methods={typesafe.objectValues(methods).map((method) => ({
        id: method.id,
        method: method.data.type,
        value: verifiedMethodPrimaryValue(method),
      }))}
      notifications={notifications
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
        .filter(notNullish)}
      deleteNotification={{
        id: deleteNotificationId,
        start: (id) => dispatch(startEntityDelete({ type: `Notification`, id })),
        confirm: () =>
          deleteNotificationId && dispatch(deleteNotification(deleteNotificationId)),
        cancel: () => dispatch(cancelEntityDelete(`Notification`)),
      }}
    />
  );
};

export default ProfileContainer;

// helpers

function verifiedMethodPrimaryValue(method: VerifiedNotificationMethod): string {
  switch (method.data.type) {
    case `email`:
      return method.data.email;
    case `slack`:
      return method.data.channelId;
    case `text`:
      return method.data.phoneNumber;
  }
}
