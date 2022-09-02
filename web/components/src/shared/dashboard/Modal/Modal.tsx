import React from 'react';
import { Fragment } from 'react';
import { Dialog, Transition } from '@headlessui/react';

interface Props {
  type: 'destructive';
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
        <div className="fixed inset-0 bg-black/60 bg-opacity-75 transition-opacity" />
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
                  <div className="mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100/75 sm:mx-0 zsm:h-10 zsm:w-10">
                    <i className="fa fa-exclamation-triangle text-red-700 -mt-px -translate-y-px text-2xl" />
                  </div>
                  <div className="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
                    <Dialog.Title
                      as="h3"
                      className="text-lg font-medium leading-6 text-gray-900"
                    >
                      {title}
                    </Dialog.Title>
                    <div className="mt-2">
                      {children && <p className="text-sm text-gray-500">{children}</p>}
                    </div>
                  </div>
                </div>
              </div>
              <div className="bg-gray-50 px-4 py-3 flex flex-col sm:flex-row sm:px-6 sm:justify-end">
                <button
                  type="button"
                  className="mt-3 sm:mt-0 sm:mr-3 order-2 inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-base font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-violet-500/80 focus:ring-offset-2 sm:w-auto sm:text-sm"
                  onClick={onDismiss}
                >
                  {secondaryButtonText}
                </button>
                <button
                  type="button"
                  className="sm:order-3 inline-flex w-full justify-center rounded-md border border-transparent bg-red-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 sm:w-auto sm:text-sm"
                  onClick={onPrimaryClick}
                >
                  {primaryButtonText}
                </button>
              </div>
            </Dialog.Panel>
          </Transition.Child>
        </div>
      </div>
    </Dialog>
  </Transition.Root>
);

export default Modal;
