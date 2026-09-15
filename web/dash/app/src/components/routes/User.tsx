import { ApiErrorMessage, EditChild, Loading } from '@dash/components';
import React, { useEffect, useMemo, useReducer } from 'react';
import { Navigate, useParams } from 'react-router-dom';
import { v4 as uuid } from 'uuid';
import type { Child, PrepIOSAppConnection } from '@dash/types';
import Current from '../../environment';
import {
  Key,
  useComputerStatuses,
  useConfirmableDelete,
  useMutation,
  useQuery,
} from '../../hooks';
import ReqState from '../../lib/ReqState';
import * as empty from '../../lib/empty';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';

const UserRoute: React.FC = () => {
  const { userId: id = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.child(id);
  const deleteChild = useConfirmableDelete(`child`, { id });
  const deleteComputerUser = useConfirmableDelete(`computerUser`, {
    invalidating: [queryKey],
  });

  const getChildQuery = useQuery(queryKey, () => Current.api.getChild(id), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
    enabled: id !== `new` && state.child?.isNew !== true,
  });
  const statusesQuery = useComputerStatuses();

  const addDevice = useMutation((childId: UUID) =>
    Current.api.macAppConnectionCode({ childId }),
  );
  const addIOSDevice = useMutation((childId: UUID) =>
    Current.api.iOSAppConnectionCode({ childId }),
  );
  const prepIOSConnection = useMutation((input: PrepIOSAppConnection.Input) =>
    Current.api.prepIOSAppConnection(input),
  );
  const startTrial = useMutation(() => Current.api.startFullTrial());

  const saveChild = useMutation(
    (child: Editable<Child>) =>
      Current.api.saveUser({
        id: child.draft.id,
        isNew: child.isNew ?? false,
        name: child.draft.name,
        keyloggingEnabled: child.draft.keyloggingEnabled,
        screenshotsEnabled: child.draft.screenshotsEnabled,
        screenshotsFrequency: child.draft.screenshotsFrequency,
        screenshotsResolution: child.draft.screenshotsResolution,
        showSuspensionActivity: child.draft.showSuspensionActivity,
        filteringDisabled: child.draft.filteringDisabled,
        downtime: child.draft.downtime,
        keychains: child.draft.keychains.map(({ id, schedule }) => ({ id, schedule })),
        blockedApps: child.draft.blockedApps,
      }),
    {
      onSuccess: () => dispatch({ type: `childSaved` }),
      invalidating: [queryKey],
      toast: `save:user`,
    },
  );

  const newChildId = useMemo(() => uuid(), []);
  useEffect(() => {
    if (id === `new`) {
      dispatch({ type: `setChild`, child: empty.child(newChildId), new: true });
    }
  }, [id, newChildId]);

  if (id === `new`) {
    return <Navigate to={`/children/${newChildId}`} replace />;
  }

  if (deleteChild.state === `success`) {
    return <Navigate to="/children" />;
  }

  if (getChildQuery.isError) {
    return <ApiErrorMessage error={getChildQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  const { child } = state;
  const { draft, original } = child;
  const computers = original.computers.map((computer) => ({
    ...computer,
    status:
      statusesQuery.data?.find((status) => status.computerUserId === computer.id)
        ?.status ?? computer.status,
  }));

  return (
    <EditChild
      isNew={state.child.isNew || false}
      name={draft.name}
      id={draft.id}
      setName={(name) => dispatch({ type: `setName`, name })}
      computers={computers}
      iosDevices={original.iosDevices}
      deleteUser={deleteChild}
      startAddDevice={() => addDevice.mutate(id)}
      dismissAddDevice={() => addDevice.reset()}
      addDeviceRequest={ReqState.fromMutation(addDevice)}
      startAddIOSDevice={() => addIOSDevice.mutate(id)}
      dismissAddIOSDevice={() => addIOSDevice.reset()}
      addIOSDeviceRequest={ReqState.fromMutation(addIOSDevice)}
      onStartTrial={() => startTrial.mutate(undefined)}
      prepIOSConnection={prepIOSConnection.mutate}
      iosSetupRequest={ReqState.fromMutation(prepIOSConnection)}
      resetIOSSetup={prepIOSConnection.reset}
      deleteDevice={deleteComputerUser}
      saveButtonDisabled={
        !isDirty(state.child) || draft.name.trim() === `` || saveChild.isPending
      }
      onSave={() => saveChild.mutate(child)}
    />
  );
};

export default UserRoute;

// helpers
