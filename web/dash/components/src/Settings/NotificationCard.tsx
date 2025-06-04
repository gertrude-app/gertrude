import React, { useEffect, useRef } from 'react';
import cx from 'classnames';
import { prettyE164 } from '@dash/utils';
import { Button, SelectMenu } from '@shared/components';
import { capitalize } from '@shared/string';
import type { AdminNotificationTrigger, VerifiedNotificationMethod } from '@dash/types';
import GradientIcon from '../GradientIcon';

type Props = {
  trigger: AdminNotificationTrigger;
  methodOptions: Array<{ display: string; value: string }>;
  selectedMethod: VerifiedNotificationMethod;
  onDelete(): unknown;
  editing: boolean;
  startEdit(): unknown;
  cancelEdit(): unknown;
  updateMethod(id: UUID): unknown;
  updateTrigger(trigger: AdminNotificationTrigger): unknown;
  onSave(): unknown;
  saveButtonDisabled: boolean;
  isNew: boolean;
  showSecurityEventOption: boolean;
};

const NotificationCard: React.FC<Props> = ({
  trigger,
  selectedMethod,
  methodOptions,
  onDelete,
  editing,
  startEdit,
  cancelEdit,
  updateMethod,
  updateTrigger,
  onSave,
  saveButtonDisabled,
  showSecurityEventOption,
  isNew,
}) => {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (isNew && ref.current) {
      ref.current.focus();
      ref.current.scrollIntoView({ behavior: `smooth` });
    }
  }, [isNew]);

  return (
    <div
      ref={ref}
      className={cx(
        `shadow-lg shadow-slate-300/50 border-[0.5px] border-slate-200 rounded-xl w-full sm:w-128 flex flex-col bg-white mx-0 xs:mx-2 sm:mx-3 my-2 sm:my-3`,
        isNew && `ring-violet-500/90 ring-4 ring-offset-4`,
      )}
    >
      <Summary {...selectedMethod} trigger={trigger} />
      <div
        className={cx(
          `p-4 space-y-4 -mt-4 duration-150 transition-[height,opacity] flex-grow`,
          editing ? `h-56` : `h-0 opacity-0 overflow-hidden`,
        )}
      >
        <div>
          <h3 className="mb-1 text-violet-800 font-medium text-md ml-1">Method:</h3>
          <SelectMenu
            options={methodOptions}
            selectedOption={selectedMethod.id}
            setSelected={updateMethod}
          />
        </div>
        <div>
          <h3 className="mb-1 text-violet-800 font-medium text-md ml-1">Upon:</h3>
          <SelectMenu
            options={[
              {
                value: `suspendFilterRequestSubmitted`,
                display: `Suspension requests`,
              },
              {
                value: `unlockRequestSubmitted`,
                display: `Unlock requests`,
              },
              ...(showSecurityEventOption
                ? [
                    {
                      value: `adminChildSecurityEvent`,
                      display: `Admin-child security events`,
                    },
                  ]
                : []),
            ]}
            selectedOption={trigger}
            setSelected={updateTrigger}
          />
        </div>
      </div>
      <div className="bg-slate-50 rounded-b-xl flex justify-between items-center p-3 px-4">
        <GradientIcon
          icon={methodIcon(selectedMethod)}
          size="medium"
          className="shrink-0 hidden xs:flex"
        />
        <div className="flex flex-col xs:flex-row xs:justify-end flex-grow">
          <Button
            type="button"
            onClick={startEdit}
            color="tertiary"
            className={cx(editing ? `hidden` : `block`, `w-[100%] xs:w-auto`)}
          >
            <i className="fa fa-pen mr-3" />
            Edit
          </Button>
          <Button
            type="button"
            onClick={onDelete}
            color="warning"
            className={cx(
              editing ? `hidden` : `block`,
              `mt-3 xs:mt-0 xs:ml-3 w-[100%] xs:w-auto`,
            )}
            testId="delete-notification"
          >
            <i className="fa fa-trash mr-3" />
            Delete
          </Button>
          <Button
            type="button"
            onClick={cancelEdit}
            color="tertiary"
            className={cx(
              editing ? `block` : `hidden`,
              `mb-3 xs:mb-0 xs:mr-3 w-[100%] xs:w-auto`,
            )}
          >
            Cancel
          </Button>
          <Button
            type="button"
            onClick={onSave}
            color="secondary"
            disabled={saveButtonDisabled}
            className={cx(editing ? `block` : `hidden`, `w-[100%] xs:w-auto`)}
          >
            Save
          </Button>
        </div>
      </div>
    </div>
  );
};

export default NotificationCard;

const Summary: React.FC<
  VerifiedNotificationMethod & { trigger: AdminNotificationTrigger }
> = (props) => (
  <div className="p-5">
    <h2 className="text-slate-700 text-lg">
      {capitalize(props.config.case)}
      {` `}
      <span className="font-bold">{methodTarget(props)}</span> for{` `}
      {triggerText(props.trigger)}
    </h2>
  </div>
);

function methodTarget(method: VerifiedNotificationMethod): string {
  switch (method.config.case) {
    case `email`:
      return method.config.email;
    case `text`:
      return prettyE164(method.config.phoneNumber);
    case `slack`:
      return method.config.channelName;
  }
}

function triggerText(trigger: AdminNotificationTrigger): string {
  switch (trigger) {
    case `suspendFilterRequestSubmitted`:
      return `filter suspension requests`;
    case `unlockRequestSubmitted`:
      return `unlock requests`;
    case `adminChildSecurityEvent`:
      return `admin-child security events`;
  }
}

function methodIcon(method: VerifiedNotificationMethod): `email` | `slack` | `phone` {
  switch (method.config.case) {
    case `text`:
      return `phone`;
    default:
      return method.config.case;
  }
}
