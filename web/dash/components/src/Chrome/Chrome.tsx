import React, { Fragment } from 'react';
import cx from 'classnames';
import { Dialog, Transition } from '@headlessui/react';
import { XMarkIcon } from '@heroicons/react/24/solid';
import SidebarNav from './SidebarNav';
import MobileStickyHeader from './MobileStickyHeader';

interface Props {
  children: React.ReactNode;
  urlPath: string;
  mobileSidebarOpen: boolean;
  onMobileHamburgerClick(): unknown;
  onMobileSidebarClose(): unknown;
  onInternalLinkClick(): unknown;
  sidebarCollapsed: boolean;
  onToggleSidebarCollapsed(): unknown;
  usingMobileView?: boolean;
}

const Chrome: React.FC<Props> = ({
  children,
  mobileSidebarOpen,
  onMobileHamburgerClick,
  onMobileSidebarClose,
  urlPath,
  sidebarCollapsed,
  onToggleSidebarCollapsed,
  onInternalLinkClick,
  usingMobileView = false,
}) => (
  <div className="Chrome bg-slate-50">
    {/* mark: begin mobile menu */}
    <Transition.Root show={mobileSidebarOpen} as={Fragment}>
      <Dialog as="div" className="relative z-40 md:hidden" onClose={onMobileSidebarClose}>
        <Transition.Child
          as={Fragment}
          enter="transition-opacity ease-linear duration-300"
          enterFrom="opacity-0"
          enterTo="opacity-100"
          leave="transition-opacity ease-linear duration-300"
          leaveFrom="opacity-100"
          leaveTo="opacity-0"
        >
          {/* mark: semi transparent overlay */}
          <div className="fixed inset-0 bg-slate-100 bg-opacity-70" />
        </Transition.Child>

        <div className="fixed inset-0 flex z-40">
          <Transition.Child
            as={Fragment}
            enter="transition ease-in-out duration-300 transform"
            enterFrom="-translate-x-full"
            enterTo="translate-x-0"
            leave="transition ease-in-out duration-300 transform"
            leaveFrom="translate-x-0"
            leaveTo="-translate-x-full"
          >
            {/* mark: begin mobile sidebar wrapper */}
            <Dialog.Panel className="relative flex flex-col w-72 bg-white rounded-r-xl shadow-lg shadow-slate-300/30">
              {/* mark: begin floating mobile overlay close 'X' button */}
              <Transition.Child
                as={Fragment}
                enter="ease-in-out duration-300"
                enterFrom="opacity-0"
                enterTo="opacity-100"
                leave="ease-in-out duration-300"
                leaveFrom="opacity-100"
                leaveTo="opacity-0"
              >
                <div className="absolute top-0 right-0 -mr-12 pt-4">
                  <button
                    type="button"
                    className="shadow-lg shadow-slate-500/30 hover:bg-slate-50 flex items-center justify-center h-10 w-10 bg-white rounded-lg focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50"
                    onClick={onMobileSidebarClose}
                  >
                    <span className="sr-only">Close sidebar</span>
                    <XMarkIcon className="h-6 leading-none text-slate-400" />
                  </button>
                </div>
              </Transition.Child>
              {/* mark: end floating mobile overlay close 'X' button */}
              <SidebarNav onInternalLinkClick={onInternalLinkClick} urlPath={urlPath} />
            </Dialog.Panel>
            {/* mark: end mobile sidebar wrapper */}
          </Transition.Child>
          <div className="flex-shrink-0 w-14" aria-hidden="true">
            {/* Dummy element to force sidebar to shrink to fit close icon */}
          </div>
        </div>
      </Dialog>
    </Transition.Root>
    {/* mark: end mobile menu */}

    {/* Static sidebar for desktop */}
    <div
      className={cx(
        sidebarCollapsed ? `w-20` : `w-72`,
        `hidden relative flex-col md:flex md:fixed md:inset-y-0 transition-[width] m-4`,
        `bg-white rounded-2xl shadow-lg shadow-slate-500/20`,
      )}
    >
      <SidebarNav
        collapsed={sidebarCollapsed}
        toggleCollapsed={onToggleSidebarCollapsed}
        onInternalLinkClick={onInternalLinkClick}
        urlPath={urlPath}
      />
    </div>

    <div
      className={cx(
        `flex flex-col flex-1 transition-[padding]`,
        sidebarCollapsed ? `md:pl-24` : `md:pl-[304px]`,
      )}
    >
      <MobileStickyHeader
        className="sticky z-20 md:hidden"
        sidebarShown={mobileSidebarOpen}
        onHamburgerClick={onMobileHamburgerClick}
      />
      <main
        // simplify this when react supports `inert` properly
        ref={(node) =>
          node &&
          (usingMobileView && mobileSidebarOpen
            ? node.setAttribute(`inert`, ``)
            : node.removeAttribute(`inert`))
        }
      >
        <div className={`[min-height:calc(100vh-64px)] md:min-h-screen`}>
          <PaddedMain>{children}</PaddedMain>
        </div>
      </main>
    </div>
  </div>
);

export default Chrome;

const PaddedMain: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  // 👋 if you change this padding, you need to change the "Undo" below
  <div className="py-6 md:py-7 max-w-[1460px] px-4 sm:px-6 md:px-8">{children}</div>
);

export const UndoMainPadding: React.FC<{
  children: React.ReactNode;
  className?: string;
}> = ({ children, className }) => (
  <div className={cx(`-my-6 md:-my-7 -mx-4 sm:-mx-6 md:-mx-8`, className)}>
    {children}
  </div>
);
