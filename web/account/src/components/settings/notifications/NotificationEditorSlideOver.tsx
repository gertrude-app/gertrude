import { Button, Select, SlideOver } from '@gertrude/ui';
import { PauseCircleIcon, ShieldAlertIcon, UnlockIcon } from 'lucide-react';
import React from 'react';
import type {
  Notification,
  NotificationMethod,
  NotificationTrigger,
} from '#/components/types';
import {
  notificationMethodIcon,
  notificationMethodSelectLabel,
} from './notificationMethodUtils';
import {
  type NotificationTriggerCategory,
  type SecurityEventLevel,
  getNotificationTriggerCategory,
  getSecurityLevel,
  notificationTriggerFromSecurityLevel,
} from './notificationTriggerUtils';

export type NotificationDraft = {
  methodId: string;
  trigger: NotificationTrigger;
};

type Props = {
  open: boolean;
  notification?: Notification;
  methods: NotificationMethod[];
  onOpenChange: (open: boolean) => void;
  onSave: (draft: NotificationDraft) => void;
};

const triggerCategoryOptions = [
  {
    value: `suspendFilterRequestSubmitted`,
    label: `Suspension requests`,
    icon: PauseCircleIcon,
  },
  {
    value: `unlockRequestSubmitted`,
    label: `Unlock requests`,
    icon: UnlockIcon,
  },
  {
    value: `securityEvents`,
    label: `Security events`,
    icon: ShieldAlertIcon,
  },
] as const;

const securityLevelOptions = [
  {
    value: `recommended`,
    label: `Recommended (highest-risk only)`,
  },
  {
    value: `medium`,
    label: `Medium (more events)`,
  },
  {
    value: `all`,
    label: `All (every event)`,
  },
] as const;

const NotificationEditorSlideOver: React.FC<Props> = ({
  open,
  notification,
  methods,
  onOpenChange,
  onSave,
}) => {
  const [draftMethodId, setDraftMethodId] = React.useState(``);
  const [draftTrigger, setDraftTrigger] = React.useState<NotificationTrigger>(
    `suspendFilterRequestSubmitted`,
  );
  const methodOptions = methods.map((method) => ({
    value: method.id,
    label: notificationMethodSelectLabel(method),
    icon: notificationMethodIcon(method, `h-3.5 w-3.5 shrink-0`),
  }));
  const triggerCategory = getNotificationTriggerCategory(draftTrigger);
  const securityLevel = getSecurityLevel(draftTrigger) ?? `recommended`;
  const hasChanges = notification
    ? draftMethodId !== notification.methodId || draftTrigger !== notification.trigger
    : true;
  const saveDisabled = draftMethodId === `` || !hasChanges;

  React.useEffect(() => {
    if (!open) {
      return;
    }

    setDraftMethodId(notification?.methodId ?? methods[0]?.id ?? ``);
    setDraftTrigger(notification?.trigger ?? `suspendFilterRequestSubmitted`);
  }, [open, notification?.id, notification?.methodId, notification?.trigger, methods]);

  const changeTriggerCategory = (category: NotificationTriggerCategory): void => {
    setDraftTrigger(
      category === `securityEvents` ? `securityEventsRecommended` : category,
    );
  };

  const changeSecurityLevel = (level: SecurityEventLevel): void => {
    setDraftTrigger(notificationTriggerFromSecurityLevel(level));
  };

  const handleSave = (): void => {
    if (saveDisabled) {
      return;
    }

    onSave({ methodId: draftMethodId, trigger: draftTrigger });
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={onOpenChange}
      ariaLabel={notification ? `Edit notification` : `Add notification`}
      heading={notification ? `Edit notification` : `Add notification`}
      subheading="Choose a verified method and the event that should trigger it."
      size="medium"
      withPx
    >
      <div className="flex h-full flex-col">
        <div className="min-h-0 flex-1 overflow-y-auto pb-6">
          {methods.length === 0 ? (
            <div className="rounded-xl border border-stone-200 bg-white p-4 text-sm leading-6 text-stone-600 shadow shadow-stone-300/30">
              Add a notification method before creating custom notifications.
            </div>
          ) : (
            <div className="flex max-w-xl flex-col gap-5">
              <Select
                label="Method"
                selected={draftMethodId}
                setSelected={setDraftMethodId}
                possibleValues={methodOptions}
              />
              <Select
                label="Event"
                selected={triggerCategory}
                setSelected={changeTriggerCategory}
                possibleValues={triggerCategoryOptions}
              />
              {triggerCategory === `securityEvents` && (
                <Select
                  label="Level"
                  selected={securityLevel}
                  setSelected={changeSecurityLevel}
                  possibleValues={securityLevelOptions}
                />
              )}
            </div>
          )}
        </div>
        <div className="-mx-4 flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-4 py-3 @lg/slide:-mx-6 @lg/slide:px-6 @lg/slide:py-4">
          <Button type="button" variant="ghost" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            type="button"
            variant="primary"
            disabled={saveDisabled}
            onClick={handleSave}
          >
            {notification ? `Save changes` : `Create notification`}
          </Button>
        </div>
      </div>
    </SlideOver>
  );
};

export default NotificationEditorSlideOver;
