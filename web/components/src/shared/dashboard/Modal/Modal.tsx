import React from 'react';
import cx from 'classnames';
import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import Button from '../../Button';
import { capitalize } from '../lib/string';
import LoadingSpinner from '../../LoadingSpinner';
import GradientIcon, { IconType } from '../GradientIcon/GradientIcon';

interface Props {
  type: 'destructive' | 'default' | 'container' | 'error';
  title: string;
  primaryButtonText?: string | React.ReactNode;
  secondaryButtonText?: string;
  isOpen: boolean;
  loading?: boolean;
  onPrimaryClick(): unknown;
  onDismiss(): unknown;
  primaryButtonDisabled?: boolean;
  children?: React.ReactNode;
  icon?: IconType;
}

const Modal: React.FC<Props> = ({
  isOpen,
  title,
  primaryButtonText = `OK`,
  secondaryButtonText = `Cancel`,
  primaryButtonDisabled = false,
  onPrimaryClick,
  onDismiss,
  type,
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
        icon = `bug`;
    }
  }

  return (
    <Transition.Root show={isOpen} as={Fragment}>
      <Dialog as="div" className="relative z-10" onClose={onDismiss}>
        <Transition.Child
          as={Fragment}
          enter="ease-out duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="ease-in duration-200"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          <div className="fixed inset-0 bg-gradient-to-b bg-gray-900/70 from-transparent via-transparent to-violet-900/20 bg-opacity-75 transition-opacity" />
        </Transition.Child>

        <div className="fixed inset-0 z-10 overflow-y-auto">
          <div className="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
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
                  <LoadingSpinner />
                </Dialog.Panel>
              ) : (
                <Dialog.Panel
                  className={cx(
                    `relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg`,
                    type === `container` && `lg:max-w-3xl`,
                  )}
                >
                  {type === `container` ? (
                    <div className="bg-white px-4 pt-5 pb-4 sm:p-4">
                      <div className="flex justify-start items-center mb-5">
                        <GradientIcon icon={icon} size="large" />
                        <Dialog.Title
                          as="h3"
                          className="text-xl ml-4 font-semibold leading-6 text-gray-900"
                        >
                          {capitalize(title)}
                        </Dialog.Title>
                      </div>
                      <div>{children}</div>
                    </div>
                  ) : (
                    <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                      <div className="sm:flex sm:items-start">
                        <GradientIcon icon={icon} size="large" />
                        <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                          <Dialog.Title
                            as="h3"
                            className="text-lg font-semibold leading-6 text-gray-900"
                          >
                            {capitalize(title)}
                          </Dialog.Title>
                          <div className="mt-2">
                            {children && (
                              <p className="text-sm text-gray-500">{children}</p>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}
                  <div className="sm:bg-gray-50 px-4 py-3 flex flex-col items-stretch sm:flex-row sm:px-6 sm:justify-end">
                    {type !== `error` && (
                      <Button
                        type="button"
                        small
                        color="secondary-white"
                        className="sm:mr-3 w-[100%] sm:w-auto mb-3 sm:mb-0"
                        onClick={onDismiss}
                      >
                        {secondaryButtonText}
                      </Button>
                    )}
                    <Button
                      type="button"
                      disabled={primaryButtonDisabled}
                      small
                      color={
                        type === `destructive` || type === `error`
                          ? `secondary-warning`
                          : `primary-violet`
                      }
                      className="w-[100%] sm:w-auto"
                      onClick={type === `error` ? onDismiss : onPrimaryClick}
                    >
                      {primaryButtonText}
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
