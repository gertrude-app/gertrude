import {
  Button,
  Label,
  Loading as LoadingAnimation,
  TextInput,
} from '@shared/components';
import { inflect } from '@shared/string';
import cx from 'classnames';
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import type {
  ChildComputer,
  ChildIOSDevice,
  ConfirmableEntityAction,
  IOSAppConnectionCode,
  MacAppConnectionCode,
  PrepIOSAppConnection,
  RequestState,
} from '@dash/types';
import { IOSConnectionCodeScreen, PlatformOption } from '../Dashboard/Dashboard';
import EmptyState from '../EmptyState';
import GradientIcon from '../GradientIcon';
import { ConfirmDeleteEntity } from '../Modal';
import PageHeading from '../PageHeading';
import AddDeviceInstructions from './AddDeviceInstructions';
import ConnectDeviceModal from './ConnectDeviceModal';
import ConnectIOSAppModal from './ConnectIOSAppModal';
import DeviceCard from './DeviceCard';

interface Props {
  id: string;
  isNew: boolean;
  name: string;
  setName(name: string): unknown;
  computers: ChildComputer[];
  iosDevices: ChildIOSDevice[];
  deleteUser: ConfirmableEntityAction<void>;
  startAddDevice(): unknown;
  dismissAddDevice(): unknown;
  startAddIOSDevice(): unknown;
  dismissAddIOSDevice(): unknown;
  onStartTrial(): unknown;
  deleteDevice: ConfirmableEntityAction;
  addDeviceRequest?: RequestState<MacAppConnectionCode.Output>;
  addIOSDeviceRequest?: RequestState<IOSAppConnectionCode.Output>;
  prepIOSConnection?(input: PrepIOSAppConnection.Input): unknown;
  iosSetupRequest?: RequestState<PrepIOSAppConnection.Output>;
  resetIOSSetup?(): unknown;
  saveButtonDisabled: boolean;
  onSave(): unknown;
}

const EditChild: React.FC<Props> = ({
  isNew,
  name,
  id,
  setName,
  computers,
  iosDevices,
  deleteDevice,
  deleteUser,
  saveButtonDisabled,
  onSave,
  dismissAddDevice,
  addDeviceRequest,
  startAddDevice,
  startAddIOSDevice,
  dismissAddIOSDevice,
  addIOSDeviceRequest,
  prepIOSConnection,
  iosSetupRequest = { state: `idle` },
  resetIOSSetup,
  onStartTrial,
}) => {
  const [platform, setPlatform] = useState<`mac` | `ios`>();
  if (isNew) {
    return (
      <div className="-my-6 md:-my-7 py-6 md:py-7 min-h-[calc(100vh-64px)] md:min-h-screen flex flex-col">
        <PageHeading icon="user-plus">Add a child</PageHeading>
        <div className="flex-grow flex items-center justify-center">
          <div className="flex flex-col gap-2 flex-grow max-w-2xl">
            <Label htmlFor="name" className="text-xl ml-6 md:ml-9">
              Child&rsquo;s name:
            </Label>
            <input
              className="border-[0.5px] border-slate-200 shadow text-2xl md:text-3xl lg:text-4xl px-6 md:px-8 py-3 md:py-4 rounded-2xl md:rounded-3xl placeholder:text-slate-200 outline-none outline-transparent outline-offset-0 focus:outline-2 focus:outline-violet-500 transition duration-200 focus:shadow-md font-medium text-slate-800 placeholder:font-normal"
              id="name"
              name="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              type="text"
              data-test="user-name"
              autoFocus
            />
          </div>
        </div>
        <footer className="flex flex-col sm:flex-row justify-end gap-4">
          <Button size="large" type="link" color="tertiary" to="/children">
            Cancel
          </Button>
          <Button
            size="large"
            type="button"
            color="primary"
            onClick={onSave}
            disabled={saveButtonDisabled}
          >
            Save child
          </Button>
        </footer>
      </div>
    );
  }
  return (
    <div className="relative max-w-3xl">
      <ConnectDeviceModal
        request={addDeviceRequest}
        dismissAddDevice={dismissAddDevice}
        onStartTrial={onStartTrial}
      />
      <ConnectIOSAppModal
        request={addIOSDeviceRequest}
        dismissModal={dismissAddIOSDevice}
        childName={name}
      />
      <ConfirmDeleteEntity
        type="connection to computer"
        action={deleteDevice}
        text="Are you sure you want to delete the connection between this child and this computer?"
      />
      <ConfirmDeleteEntity type="child" action={deleteUser} />
      {(computers.length > 0 || iosDevices.length > 0) && (
        <PageHeading icon={`cog`}>Child settings</PageHeading>
      )}
      <div className="mt-8">
        {computers.length === 0 && iosDevices.length === 0 && (
          <div className="-mt-6 bg-white rounded-3xl p-6 sm:p-8 shadow border-[0.5px] border-slate-200">
            {!platform ? (
              <div className="flex flex-col items-center">
                <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
                  Connect a device for {name}
                </h1>
                <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
                  What type of device would you like to connect?
                </p>
                <div className="mt-12 flex flex-col sm:flex-row gap-4 w-full max-w-lg">
                  <PlatformOption
                    icon="fa-solid fa-laptop"
                    title="Mac computer"
                    onClick={() => setPlatform(`mac`)}
                  />
                  <PlatformOption
                    icon="fa-solid fa-mobile-screen"
                    title="iPhone or iPad"
                    onClick={() => {
                      setPlatform(`ios`);
                      prepIOSConnection?.({
                        child: { case: `existingChild`, id },
                      });
                    }}
                  />
                </div>
              </div>
            ) : platform === `mac` ? (
              <>
                <button
                  onClick={() => setPlatform(undefined)}
                  className="text-slate-400 hover:text-slate-600 transition-colors text-sm mb-2"
                >
                  <i className="fa-solid fa-arrow-left mr-1.5" />
                  Back
                </button>
                <AddDeviceInstructions
                  userName={name}
                  userId={id}
                  startAddDevice={startAddDevice}
                />
              </>
            ) : iosSetupRequest.state === `succeeded` ? (
              <div className="flex flex-col items-center">
                <IOSConnectionCodeScreen
                  childName={name}
                  code={iosSetupRequest.payload.code}
                />
              </div>
            ) : iosSetupRequest.state === `failed` ? (
              <div className="flex flex-col items-center">
                <button
                  onClick={() => {
                    setPlatform(undefined);
                    resetIOSSetup?.();
                  }}
                  className="self-start text-slate-400 hover:text-slate-600 transition-colors text-sm mb-2"
                >
                  <i className="fa-solid fa-arrow-left mr-1.5" />
                  Back
                </button>
                <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
                  Something went wrong
                </h1>
                <p className="text-base xs:text-lg sm:text-xl text-slate-600 text-center mt-4 max-w-xl">
                  We weren't able to get a connection code. Please try again.
                </p>
                <div className="mt-8">
                  <Button
                    type="button"
                    color="primary"
                    onClick={() =>
                      prepIOSConnection?.({
                        child: { case: `existingChild`, id },
                      })
                    }
                  >
                    Try again
                  </Button>
                </div>
              </div>
            ) : (
              <div className="flex flex-col items-center">
                <h1 className="font-inter text-2xl xs:text-3xl lg:text-4xl text-center">
                  Setting things up...
                </h1>
                <div className="mt-8">
                  <LoadingAnimation />
                </div>
              </div>
            )}
          </div>
        )}
        {(computers.length > 0 || iosDevices.length > 0) && (
          <>
            <h2 className="text-lg font-bold text-slate-700 mb-2">Name:</h2>
            <div className="flex items-end gap-3 max-w-2xl">
              <TextInput type="text" testId="user-name" value={name} setValue={setName} />
              <Button
                className={cx(
                  `ScrollTop shrink-0 transition-opacity duration-200`,
                  saveButtonDisabled && `opacity-0 pointer-events-none`,
                )}
                type="button"
                onClick={onSave}
                color="primary"
                size="large"
              >
                Save
              </Button>
            </div>
            <div className="mt-10 max-w-3xl">
              <h2 className="text-lg font-bold text-slate-700 mb-3">
                Protection settings:
              </h2>
              <div className="flex flex-col sm:flex-row gap-3">
                <Link
                  to={`/children/${id}/mac`}
                  className="flex items-center rounded-xl px-5 py-8 sm:w-1/2 bg-violet-50 hover:bg-violet-100 transition duration-200 border border-violet-200"
                >
                  <GradientIcon icon="laptop" size="large" className="mr-4 shrink-0" />
                  <h3 className="text-lg font-semibold text-slate-700 flex-grow">
                    For Mac Computers
                  </h3>
                  <i className="fa-solid fa-chevron-right text-violet-400 ml-2" />
                </Link>
                <Link
                  to={
                    iosDevices.length === 1
                      ? `/children/${id}/ios-devices/${iosDevices[0]?.id || ``}`
                      : `/children/${id}/ios-devices`
                  }
                  className="flex items-center rounded-xl px-5 py-8 sm:w-1/2 bg-violet-50 hover:bg-violet-100 transition duration-200 border border-violet-200"
                >
                  <GradientIcon icon="phone" size="large" className="mr-4 shrink-0" />
                  <h3 className="text-lg font-semibold text-slate-700 flex-grow">
                    For iPhones and iPads
                  </h3>
                  <i className="fa-solid fa-chevron-right text-violet-400 ml-2" />
                </Link>
              </div>
            </div>

            <div className="mt-8 max-w-3xl flex flex-col gap-4">
              <div className={computers.length > 0 ? `order-first` : `order-last`}>
                <h2 className="text-lg font-bold text-slate-700">
                  {computers.length > 0 ? (
                    <>
                      {computers.length} {inflect(`computer`, computers.length)}:
                    </>
                  ) : (
                    `Computers:`
                  )}
                </h2>
                {computers.length > 0 ? (
                  <div className="flex flex-col -mx-2 xs:mx-0">
                    {computers.map((computer) => (
                      <div key={computer.id} className="flex items-center mt-3">
                        <DeviceCard
                          to={`/devices/${computer.computerId}`}
                          imageSrc={`/macs/${computer.modelIdentifier}.png`}
                          imageAlt={computer.modelTitle}
                          title={computer.customName || computer.modelTitle}
                          subtitle={computer.customName ? computer.modelTitle : undefined}
                          status={{ case: `computerStatus`, status: computer.status }}
                          className="flex-grow mr-1 xs:mr-3"
                        />
                        <button
                          onClick={() => deleteDevice.start(computer.id)}
                          className="transition-colors duration-100 flex justify-center items-center w-6 xs:w-10 h-6 xs:h-10 rounded-full hover:bg-slate-200/50 cursor-pointer text-slate-500 hover:text-red-500"
                        >
                          <i className="fa fa-trash" />
                        </button>
                      </div>
                    ))}
                    <Button
                      type="button"
                      onClick={startAddDevice}
                      color="secondary"
                      size="medium"
                      className="self-end mt-4"
                    >
                      <i className="fa fa-plus mr-2" />
                      Add a computer
                    </Button>
                  </div>
                ) : (
                  <EmptyState
                    heading="No computers"
                    secondaryText="Connect a Mac computer running the Gertrude Mac app."
                    icon="laptop"
                    buttonText="Add a computer"
                    action={startAddDevice}
                    buttonColor="secondary"
                    className="mt-2"
                  />
                )}
              </div>

              <div
                className={cx(
                  iosDevices.length > 0 ? `order-first` : `order-last`,
                  iosDevices.length === 0 && `hidden`,
                )}
              >
                <h2 className="text-lg font-bold text-slate-700">
                  {iosDevices.length > 0 ? (
                    <>
                      {iosDevices.length} iOS {inflect(`device`, iosDevices.length)}:
                    </>
                  ) : (
                    `iOS devices:`
                  )}
                </h2>
                {iosDevices.length > 0 ? (
                  <div className="flex flex-col -mx-2 xs:mx-0">
                    {iosDevices.map((device) => (
                      <div key={device.id} className="flex items-center mt-3">
                        <DeviceCard
                          to={
                            device.pendingClaimCode === undefined
                              ? `/children/${id}/ios-devices/${device.id}`
                              : `/supervise-device/${device.pendingClaimCode}/download-helper`
                          }
                          imageSrc={`/ios/${device.deviceType}.png`}
                          imageAlt={device.modelName}
                          title={device.modelName}
                          subtitle={device.iosVersion}
                          status={
                            device.pendingClaimCode !== undefined
                              ? { case: `pendingSetup` }
                              : undefined
                          }
                          className="flex-grow mr-1 xs:mr-3"
                        />
                        <button
                          disabled
                          className="flex justify-center items-center w-6 xs:w-10 h-6 xs:h-10 rounded-full text-slate-300 cursor-not-allowed"
                        >
                          <i className="fa fa-trash" />
                        </button>
                      </div>
                    ))}
                    <Button
                      type="button"
                      onClick={startAddIOSDevice}
                      color="secondary"
                      size="medium"
                      className="self-end mt-4"
                    >
                      <i className="fa fa-plus mr-2" />
                      Add a device
                    </Button>
                  </div>
                ) : (
                  <EmptyState
                    heading="No iOS devices"
                    secondaryText="Add an iPhone or iPad to manage with Gertrude."
                    icon="mobile-screen"
                    buttonText="Add a device"
                    action={startAddIOSDevice}
                    buttonColor="secondary"
                    className="mt-2"
                  />
                )}
              </div>
            </div>
          </>
        )}
        <div className="mt-12 max-w-3xl">
          <h2 className="text-lg font-bold text-slate-700 mb-3">Danger zone:</h2>
          <div className="rounded-2xl bg-slate-50 border border-red-200/60 px-6 py-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <p className="text-slate-400 text-sm">
              Permanently delete this child and all associated data.
            </p>
            <Button
              type="button"
              onClick={deleteUser.start}
              color="warning"
              className="shrink-0"
            >
              Delete child
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EditChild;
