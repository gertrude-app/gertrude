import { Button, Card, Select, SlideOver, Text, VStack } from '@gertrude/ui';
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
  defaultMethodId?: string;
  onOpenChange: (open: boolean) => void;
  onSave: (draft: NotificationDraft) => Promise<void>;
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
  defaultMethodId,
  onOpenChange,
  onSave,
}) => {
  const [draftMethodId, setDraftMethodId] = React.useState(``);
  const [draftTrigger, setDraftTrigger] = React.useState<NotificationTrigger>(
    `suspendFilterRequestSubmitted`,
  );
  const [saving, setSaving] = React.useState(false);
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
  const saveDisabled = draftMethodId === `` || !hasChanges || saving;

  React.useEffect(() => {
    if (!open) {
      return;
    }

    setDraftMethodId(notification?.methodId ?? defaultMethodId ?? methods[0]?.id ?? ``);
    setDraftTrigger(notification?.trigger ?? `suspendFilterRequestSubmitted`);
  }, [
    defaultMethodId,
    open,
    notification?.id,
    notification?.methodId,
    notification?.trigger,
    methods,
  ]);

  const changeTriggerCategory = (category: NotificationTriggerCategory): void => {
    setDraftTrigger(
      category === `securityEvents` ? `securityEventsRecommended` : category,
    );
  };

  const changeSecurityLevel = (level: SecurityEventLevel): void => {
    setDraftTrigger(notificationTriggerFromSecurityLevel(level));
  };

  const handleSave = async (): Promise<void> => {
    if (saveDisabled) {
      return;
    }

    setSaving(true);
    try {
      await onSave({ methodId: draftMethodId, trigger: draftTrigger });
    } catch {
      return;
    } finally {
      setSaving(false);
    }
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={(nextOpen) => {
        if (!saving) {
          onOpenChange(nextOpen);
        }
      }}
      ariaLabel={notification ? `Edit notification` : `Add notification`}
      heading={notification ? `Edit notification` : `Add notification`}
      subheading="Choose a verified method and the event that should trigger it."
      size="medium"
      withPx
    >
      <VStack className="h-full">
        <SlideOver.Body>
          {methods.length === 0 ? (
            <Card padding={4}>
              <Text as="p" variant="proseSubtle">
                Add a notification method before creating custom notifications.
              </Text>
            </Card>
          ) : (
            <VStack gap={5} className="max-w-xl">
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
            </VStack>
          )}
        </SlideOver.Body>
        <SlideOver.Footer bleedX>
          <Button
            type="button"
            variant="ghost"
            disabled={saving}
            onClick={() => onOpenChange(false)}
          >
            Cancel
          </Button>
          <Button
            type="button"
            variant="primary"
            disabled={saveDisabled}
            loading={saving}
            onClick={() => void handleSave()}
          >
            {notification ? `Save changes` : `Create notification`}
          </Button>
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export default NotificationEditorSlideOver;
