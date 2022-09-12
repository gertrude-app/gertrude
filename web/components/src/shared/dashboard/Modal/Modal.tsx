import React from 'react';
import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import Button from '../../Button';

interface Props {
  type: 'destructive' | 'default';
  title: string;
  primaryButtonText?: string;
  secondaryButtonText?: string;
  isOpen: boolean;
  onPrimaryClick(): unknown;
  onDismiss(): unknown;
  children?: React.ReactNode;
}

const Modal: React.FC<Props> = ({
  isOpen,
  title,
  primaryButtonText = `OK`,
  secondaryButtonText = `Cancel`,
  onPrimaryClick,
  onDismiss,
  type,
  children,
}) => (
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
            <Dialog.Panel className="relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg">
              <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
                <div className="sm:flex sm:items-start">
                  <div className="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-indigo-500 to-fuchsia-500 sm:mx-0 zsm:h-10 zsm:w-10">
                    <i
                      className={`fa fa-${
                        type === 'destructive' ? 'exclamation-triangle' : 'info'
                      } text-white -mt-px -translate-y-px text-2xl`}
                    />
                  </div>
                  <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                    <Dialog.Title
                      as="h3"
                      className="text-lg font-semibold leading-6 text-gray-900 capitalize"
                    >
                      {title}
                    </Dialog.Title>
                    <div className="mt-2">
                      {children && <p className="text-sm text-gray-500">{children}</p>}
                    </div>
                  </div>
                </div>
              </div>
              <div className="sm:bg-gray-50 px-4 py-3 flex flex-col items-stretch sm:flex-row sm:px-6 sm:justify-end">
                <Button
                  type="button"
                  small
                  color="secondary-white"
                  className="sm:mr-2 w-[100%] sm:w-auto mb-2 sm:mb-0"
                  onClick={onDismiss}
                >
                  {secondaryButtonText}
                </Button>
                <Button
                  type="button"
                  small
                  color={type === 'destructive' ? 'secondary-warning' : 'primary-violet'}
                  className="w-[100%] sm:w-auto"
                  onClick={onPrimaryClick}
                >
                  {primaryButtonText}
                </Button>
              </div>
            </Dialog.Panel>
          </Transition.Child>
        </div>
      </div>
    </Dialog>
  </Transition.Root>
);

export default Modal;
