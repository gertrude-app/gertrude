import React, { useEffect } from 'react';
import Loading from '@shared/Loading';
import Profile from '@shared/dashboard/Profile';
import { useDispatch, useSelector } from '../../redux/hooks';
import { fetchProfileData } from '../../redux/slice-admin';
import ApiErrorMessage from '../ApiErrorMessage';
import * as typesafe from '../../lib/typesafe';
import { notNullish } from '../../redux/helpers';
import { Trigger } from '../../graphqlTypes';
import { VerifiedNotificationMethod } from '../../types/Admin';

const ProfileContainer: React.FC = () => {
  const dispatch = useDispatch();
  const adminId = useSelector((state) => state.auth.admin?.id ?? ``);
  const request = useSelector((state) => state.admin.profileRequest);
  const methods = useSelector((state) => state.admin.verifiedNotificationMethods);
  const notifications = useSelector((state) => state.admin.notifications);
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
      methods={typesafe.objectValues(methods).map((m) => ({
        id: m.id,
        method: m.data.type,
        value: verifiedMethodPrimaryValue(m),
      }))}
      notifications={typesafe
        .objectValues(notifications)
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
