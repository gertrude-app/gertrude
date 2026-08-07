import { ApiErrorMessage, Loading, PageHeading, ToggleCard } from '@dash/components';
import { Button, TextInput } from '@shared/components';
import cx from 'classnames';
import React, { useReducer } from 'react';
import { Link, Navigate, useParams } from 'react-router-dom';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';
import { isDirty } from '../../lib/helpers';
import reducer from '../../reducers/user-reducer';

const MacMonitoringRoute: React.FC = () => {
  const { userId = `` } = useParams<{ userId: string }>();
  const [state, dispatch] = useReducer(reducer, {});
  const queryKey = Key.child(userId);

  const childQuery = useQuery(queryKey, () => Current.api.getChild(userId), {
    onReceive: (child) => dispatch({ type: `setChild`, child }),
  });

  const saveChild = useMutation(
    () => {
      const child = state.child;
      if (!child) throw new Error(`No child loaded`);
      return Current.api.saveMacappMonitoring({
        id: child.draft.id,
        keyloggingEnabled: child.draft.keyloggingEnabled,
        screenshotsEnabled: child.draft.screenshotsEnabled,
        screenshotsFrequency: child.draft.screenshotsFrequency,
        screenshotsResolution: child.draft.screenshotsResolution,
        showSuspensionActivity: child.draft.showSuspensionActivity,
      });
    },
    {
      onSuccess: () => dispatch({ type: `childSaved` }),
      invalidating: [queryKey],
      toast: `save:user`,
    },
  );

  if (childQuery.isError) {
    return <ApiErrorMessage error={childQuery.error} />;
  }

  if (!state.child) {
    return <Loading />;
  }

  if (state.child.original.computers.length === 0) {
    return <Navigate to=".." replace relative="path" />;
  }

  const { draft } = state.child;
  const saveDisabled = !isDirty(state.child) || saveChild.isPending;

  return (
    <div className="max-w-3xl">
      <Link
        to=".."
        relative="path"
        className="inline-flex items-center text-sm text-violet-600 hover:underline mb-4"
      >
        <i className="fa-solid fa-arrow-left mr-1.5" />
        {draft.name}&rsquo;s Mac
      </Link>
      <PageHeading icon="binoculars">Monitoring</PageHeading>

      <div className="mt-8">
        <ToggleCard
          title="Enable keylogging"
          description="Sends reports of all keystrokes to your review"
          enabled={draft.keyloggingEnabled}
          setEnabled={(enabled) => dispatch({ type: `setKeyloggingEnabled`, enabled })}
        />
        <ToggleCard
          title="Enable screenshots"
          description="Periodically take a screenshot and upload for your review"
          enabled={draft.screenshotsEnabled}
          setEnabled={(enabled) => dispatch({ type: `setScreenshotsEnabled`, enabled })}
          disabledReason={
            draft.filteringDisabled
              ? `Screenshots are required when internet filtering is disabled`
              : undefined
          }
        >
          <div
            className={cx(
              `flex flex-col space-y-3 md:flex-row md:space-x-3 md:space-y-0 mt-5`,
              draft.screenshotsEnabled || `hidden`,
            )}
          >
            <TextInput
              type="positiveInteger"
              label="Resolution"
              value={String(draft.screenshotsResolution)}
              setValue={(num) =>
                dispatch({ type: `setScreenshotsResolution`, resolution: Number(num) })
              }
              unit="pixels"
            />
            <TextInput
              type="positiveInteger"
              label="Frequency"
              value={String(draft.screenshotsFrequency)}
              setValue={(num) =>
                dispatch({ type: `setScreenshotsFrequency`, frequency: Number(num) })
              }
              unit="seconds"
            />
          </div>
        </ToggleCard>
        <ToggleCard
          title="Emphasize filter suspension activity"
          description="Visually highlight activity that is recorded while filter is suspended"
          enabled={draft.showSuspensionActivity}
          setEnabled={(show) => dispatch({ type: `setShowSuspensionActivity`, show })}
          className={cx(
            `transition-opacity duration-300`,
            !(draft.screenshotsEnabled || draft.keyloggingEnabled) && `!hidden`,
          )}
        />
      </div>

      <div className="flex mt-12 pt-8 border-t-2 border-slate-200 justify-end">
        <Button
          type="button"
          disabled={saveDisabled}
          onClick={() => saveChild.mutate(undefined)}
          color="primary"
        >
          Save settings
        </Button>
      </div>
    </div>
  );
};

export default MacMonitoringRoute;
