import {
  Dialog,
  DialogPanel,
  DialogTitle,
  Transition,
  TransitionChild,
} from '@headlessui/react';
import { Button, Loading } from '@shared/components';
import { capitalize } from '@shared/string';
import cx from 'classnames';
import React, { useEffect, useRef } from 'react';
import type { IconType } from '../GradientIcon';
import GradientIcon from '../GradientIcon';

interface Props {
  type?: `destructive` | `default` | `container` | `error`;
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

  const panelRef = useRef<HTMLDivElement>(null);

  // Headless UI v2 changed Dialog focus behavior: it now focuses the Dialog element
  // itself instead of the first focusable child. This restores the old behavior.
  useEffect(() => {
    if (!isOpen) return;
    const timeout = setTimeout(() => {
      const focusable = panelRef.current?.querySelector<HTMLElement>(
        `button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])`,
      );
      focusable?.focus({ preventScroll: true });
    }, 50);
    return () => clearTimeout(timeout);
  }, [isOpen]);

  return (
    <Transition show={isOpen}>
      <Dialog
        as="div"
        className="relative z-30"
        autoFocus
        onClose={
          onDismiss ??
          (secondary?.action
            ? secondary.action
            : type === `error`
              ? primary.action
              : () => {})
        }
      >
        <TransitionChild
          as="div"
          aria-hidden="true"
          className="fixed inset-0 bg-gradient-to-b bg-slate-900/70 from-transparent via-transparent to-violet-900/20 bg-opacity-75 transition-opacity duration-300 ease-out data-[closed]:opacity-0"
        />

        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div
            className={cx(
              `flex min-h-full items-end justify-center text-center sm:items-center sm:p-0`,
              maximizeWidthForSmallScreens ? `p-1 pt-3` : `p-4`,
            )}
          >
            <TransitionChild
              ref={panelRef}
              as={DialogPanel}
              className={cx(
                `relative transform rounded-2xl bg-white text-left shadow-xl transition-all duration-200 ease-out data-[closed]:opacity-0 data-[closed]:translate-y-4 data-[closed]:sm:translate-y-0 data-[closed]:sm:scale-95 min-w-[300px] sm:my-8 sm:w-full`,
                loading ? `` : type === `container` && `lg:max-w-4xl`,
                loading
                  ? ``
                  : maximizeWidthForSmallScreens
                    ? `w-full sm:w-auto`
                    : `sm:max-w-xl`,
              )}
            >
              {loading ? (
                <div className="p-8 rounded-3xl">
                  <Loading withWhiteBg />
                </div>
              ) : (
                <>
                  {type === `container` ? (
                    <div
                      className={cx(
                        panelInnerClasses(maximizeWidthForSmallScreens),
                        `relative sm:p-4`,
                      )}
                    >
                      <div className="flex justify-start items-center mb-5">
                        <GradientIcon icon={icon} size="large" />
                        <DialogTitle
                          as="h3"
                          className="text-xl ml-4 font-bold leading-6 text-slate-900"
                        >
                          {capitalize(title)}
                        </DialogTitle>
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
                          <DialogTitle
                            as="h3"
                            className={cx(
                              `text-xl font-bold leading-6`,
                              type === `error` ? `text-red-800` : `text-slate-900`,
                            )}
                          >
                            {capitalize(title)}
                          </DialogTitle>
                          <div className="mt-2 w-full">
                            {children && (
                              <div className="text-sm text-slate-500">{children}</div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="sm:bg-slate-50 rounded-b-2xl sm:rounded-b-3xl pb-4 sm:pb-3 p-3 flex flex-col items-stretch sm:flex-row sm:justify-end">
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
                </>
              )}
            </TransitionChild>
          </div>
        </div>
      </Dialog>
    </Transition>
  );
};

export default Modal;

// helpers

function panelInnerClasses(maximizingWidthForSmallScreens: boolean): string {
  return cx(
    `bg-white rounded-2xl sm:rounded-3xl pb-4`,
    maximizingWidthForSmallScreens ? `px-2 pt-3` : `px-4 pt-5`,
  );
}
