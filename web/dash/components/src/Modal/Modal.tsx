import React from 'react';
import cx from 'classnames';
import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import { Button, Loading } from '@shared/components';
import { capitalize } from '@shared/string';
import type { IconType } from '../GradientIcon';
import GradientIcon from '../GradientIcon';

interface Props {
  type?: 'destructive' | 'default' | 'container' | 'error';
  title: string;
  isOpen?: boolean;
  loading?: boolean;
  primaryButton:
    | (() => unknown)
    | {
        action(): unknown;
        label?: string | React.ReactNode;
        disabled?: boolean;
      };
  secondaryButton?:
    | (() => unknown)
    | {
        action(): unknown;
        label?: string | React.ReactNode;
        disabled?: boolean;
      };
  onDismiss?(): unknown;
  maximizeWidthForSmallScreens?: boolean;
  children?: React.ReactNode;
  icon?: IconType;
}

const Modal: React.FC<Props> = ({
  isOpen = true,
  title,
  type = `default`,
  maximizeWidthForSmallScreens = false,
  primaryButton,
  secondaryButton,
  onDismiss,
  children,
  icon,
  loading,
}) => {
  if (!icon) {
    switch (type) {
      case `destructive`:
        icon = `exclamation-triangle`;
        break;
      case `default`:
        icon = `info`;
        break;
      case `container`:
        icon = `list`;
        break;
      case `error`:
        icon = `question`;
        break;
    }
  }

  const primary =
    typeof primaryButton === `function`
      ? { action: primaryButton, label: `OK` }
      : primaryButton;

  const secondary =
    typeof secondaryButton === `function`
      ? { action: secondaryButton, label: `Cancel` }
      : secondaryButton;

  return (
    <Transition.Root show={isOpen} as={Fragment}>
      <Dialog
        as="div"
        className="relative z-30"
        onClose={
          onDismiss ??
          (secondary?.action
            ? secondary.action
            : type === `error`
            ? primary.action
            : () => {})
        }
      >
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-gradient-to-b bg-slate-900/70 from-transparent via-transparent to-violet-900/20 bg-opacity-75 transition-opacity" />
        </Transition.Child>

        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div
            className={cx(
              `flex min-h-full items-end justify-center text-center sm:items-center sm:p-0`,
              maximizeWidthForSmallScreens ? `p-1 pt-3` : `p-4`,
            )}
          >
            <Transition.Child
              as={Fragment}
              enter="ease-out duration-200"
              enterFrom="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              enterTo="opacity-100 translate-y-0 sm:scale-100"
              leave="ease-in duration-100"
              leaveFrom="opacity-100 translate-y-0 sm:scale-100"
              leaveTo="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
            >
              {loading ? (
                <Dialog.Panel>
                  <div className="p-8 rounded-3xl">
                    <Loading />
                  </div>
                </Dialog.Panel>
              ) : (
                <Dialog.Panel
                  className={cx(
                    `relative transform rounded-lg bg-white text-left shadow-xl transition-all min-w-[300px] sm:my-8 sm:w-full`,
                    type === `container` && `lg:max-w-4xl`,
                    maximizeWidthForSmallScreens ? `w-full sm:w-auto` : `sm:max-w-xl`,
                  )}
                >
                  {type === `container` ? (
                    <div
                      className={cx(
                        panelInnerClasses(maximizeWidthForSmallScreens),
                        `relative sm:p-4`,
                      )}
                    >
                      <div className="flex justify-start items-center mb-5">
                        <GradientIcon icon={icon} size="large" />
                        <Dialog.Title
                          as="h3"
                          className="text-xl ml-4 font-bold leading-6 text-slate-900"
                        >
                          {capitalize(title)}
                        </Dialog.Title>
                      </div>
                      <div>{children}</div>
                    </div>
                  ) : (
                    <div
                      className={cx(
                        panelInnerClasses(maximizeWidthForSmallScreens),
                        `sm:p-6 sm:pb-4`,
                      )}
                    >
                      <div className="flex flex-col sm:flex-row items-center sm:items-start">
                        <GradientIcon icon={icon} size="large" />
                        <div className="mt-3 text-center self-stretch sm:grow sm:mt-0 sm:ml-4 sm:text-left">
                          <Dialog.Title
                            as="h3"
                            className={cx(
                              `text-xl font-bold leading-6`,
                              type === `error` ? `text-red-800` : `text-slate-900`,
                            )}
                          >
                            {capitalize(title)}
                          </Dialog.Title>
                          <div className="mt-2 w-full">
                            {children && (
                              <div className="text-sm text-slate-500">{children}</div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="sm:bg-slate-50 rounded-b-lg px-4 py-3 pb-5 sm:pb-3 flex flex-col items-stretch sm:flex-row sm:px-6 sm:justify-end">
                    {secondary && (
                      <Button
                        testId="modal-secondary-btn"
                        type="button"
                        color="tertiary"
                        className="sm:mr-3 w-[100%] sm:w-auto mb-4 sm:mb-0"
                        disabled={secondary.disabled}
                        onClick={secondary.action}
                      >
                        {secondary.label ?? `Cancel`}
                      </Button>
                    )}
                    <Button
                      testId="modal-primary-btn"
                      type="button"
                      disabled={primary.disabled}
                      color={
                        type === `destructive`
                          ? `warning`
                          : type === `error`
                          ? `secondary`
                          : `primary`
                      }
                      className="w-[100%] sm:w-auto"
                      onClick={primary.action}
                    >
                      {primary.label}
                    </Button>
                  </div>
                </Dialog.Panel>
              )}
            </Transition.Child>
          </div>
        </div>
      </Dialog>
    </Transition.Root>
  );
};

export default Modal;

// helpers

function panelInnerClasses(maximizingWidthForSmallScreens: boolean): string {
  return cx(
    `bg-white rounded-lg pb-4`,
    maximizingWidthForSmallScreens ? `px-2 pt-3` : `px-4 pt-5`,
  );
}
