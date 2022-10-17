import React from 'react';
import cx from 'classnames';
import { ConfirmableEntityAction, Subcomponents } from '../../../types';
import Button from '../../../Button';
import KeychainCard from '../KeychainCard';
import TextInput from '../../../TextInput';
import Toggle from '../../Toggle';
import UserDevice from '../List/Card/Device';
import PageHeading from '../../PageHeading';
import { ConfirmDeleteEntity } from '../../Modal';
import { inflect } from '../../lib/string';
import ConnectModal from '../ConnectModal';
import AddKeychainModal from '../AddKeychainModal';

interface Props {
  isNew: boolean;
  name: string;
  setName(name: string): unknown;
  keyloggingEnabled: boolean;
  setKeyloggingEnabled(enabled: boolean): unknown;
  screenshotsEnabled: boolean;
  setScreenshotsEnabled(enabled: boolean): unknown;
  screenshotsResolution: number;
  setScreenshotsResolution(resolution: number): unknown;
  screenshotsFrequency: number;
  setScreenshotsFrequency(frequency: number): unknown;
  removeKeychain(id: UUID): unknown;
  keychains: Keychain[];
  devices: Subcomponents<typeof UserDevice>;
  deleteUser: ConfirmableEntityAction<void>;
  startAddDevice(): unknown;
  dismissAddDevice(): unknown;
  deleteDevice: ConfirmableEntityAction;
  addDeviceRequest?: RequestState<number>;
  saveButtonDisabled: boolean;
  onSave(): unknown;
  onAddKeychainClicked(): unknown;
  onSelectKeychainToAdd(keychain: Keychain): unknown;
  onConfirmAddKeychain(): unknown;
  onDismissAddKeychain(): unknown;
  selectingKeychain?: Keychain | null;
  fetchSelectableKeychainsRequest?: RequestState<{ own: Keychain[]; public: Keychain[] }>;
}

const EditUser: React.FC<Props> = ({
  isNew,
  name,
  setName,
  keyloggingEnabled,
  setKeyloggingEnabled,
  screenshotsEnabled,
  setScreenshotsEnabled,
  screenshotsResolution,
  setScreenshotsResolution,
  screenshotsFrequency,
  setScreenshotsFrequency,
  removeKeychain,
  keychains,
  devices,
  deleteDevice,
  deleteUser,
  saveButtonDisabled,
  onSave,
  dismissAddDevice,
  addDeviceRequest,
  startAddDevice,
  onAddKeychainClicked,
  onSelectKeychainToAdd,
  onDismissAddKeychain,
  fetchSelectableKeychainsRequest,
  selectingKeychain,
  onConfirmAddKeychain,
}) => (
  <div className="relative max-w-3xl">
    <ConnectModal request={addDeviceRequest} dismissAddDevice={dismissAddDevice} />
    <AddKeychainModal
      request={fetchSelectableKeychainsRequest}
      onSelect={onSelectKeychainToAdd}
      onDismiss={onDismissAddKeychain}
      onConfirm={onConfirmAddKeychain}
      selected={selectingKeychain ?? undefined}
      existingKeychains={keychains}
    />
    <ConfirmDeleteEntity type="device" action={deleteDevice} />
    <ConfirmDeleteEntity type="user" action={deleteUser} />
    <PageHeading icon={isNew ? `user-plus` : `pen`}>
      {isNew ? `Create` : `Edit`} user
    </PageHeading>
    <div className="mt-8">
      <TextInput
        type="text"
        label="Name:"
        value={name}
        setValue={setName}
        className="max-w-xl"
      />
      <h2 className="mt-5 text-lg font-bold text-gray-700">
        {devices.length} {inflect(`device`, devices.length)}:
      </h2>
      <div className="flex flex-col">
        {devices.map((device) => (
          <div key={device.id} className="flex items-center mt-3">
            <UserDevice
              model={device.model}
              status={device.status}
              icon={device.icon}
              className="flex-grow mr-3"
            />
            <button
              onClick={() => deleteDevice.start(device.id)}
              className="transition duration-100 flex justify-center items-center w-10 h-10 rounded-full hover:bg-gray-100 cursor-pointer text-gray-500 hover:text-red-500"
            >
              <i className="fa fa-trash" />
            </button>
          </div>
        ))}
        <button
          onClick={startAddDevice}
          className="mt-5 text-violet-700 font-medium px-7 py-2 rounded-lg hover:bg-violet-100 self-end transition duration-100"
        >
          <i className="fa fa-plus mr-2" />
          Add device
        </button>
      </div>
      <div className="mt-4">
        <h2 className="text-lg font-bold text-gray-700">Monitoring</h2>
        <div className="flex justify-between items-center bg-gray-100 my-3 p-4 sm:p-6 rounded-xl">
          <div className="mr-3">
            <h3 className="font-medium text-gray-700">Enable keylogging</h3>
            <p className="text-gray-500 text-sm">
              Sends reports of all keystrokes to your review
            </p>
          </div>
          <Toggle enabled={keyloggingEnabled} setEnabled={setKeyloggingEnabled} />
        </div>
        <div
          className={`bg-gray-100 my-3 p-4 sm:p-6 rounded-xl overflow-hidden relative [transition:150ms]`}
        >
          <div className="flex justify-between items-center">
            <div className="mr-3">
              <h3 className="font-medium text-gray-700">Enable screenshots</h3>
              <p className="text-gray-500 text-sm">
                Periodically take a screenshot and upload for your review
              </p>
            </div>
            <Toggle enabled={screenshotsEnabled} setEnabled={setScreenshotsEnabled} />
          </div>
          <div
            className={cx(
              `flex flex-col space-y-3 md:flex-row md:space-x-3 md:space-y-0 mt-5 transition duration-100`,
              screenshotsEnabled ? `opacity-100` : `opacity-0 hidden`,
            )}
          >
            <TextInput
              type="positiveInteger"
              label="Resolution"
              value={String(screenshotsResolution)}
              setValue={(num) => setScreenshotsResolution(Number(num))}
              unit="pixels"
            />
            <TextInput
              type="positiveInteger"
              label="Frequency"
              value={String(screenshotsFrequency)}
              setValue={(num) => setScreenshotsFrequency(Number(num))}
              unit="seconds"
            />
          </div>
        </div>
      </div>
      <div className="mt-12">
        <h2 className="text-lg font-bold text-gray-700 mb-2">Keychains</h2>
        <div className="p-3 flex flex-col space-y-4">
          {keychains.map((keychain) => (
            <KeychainCard
              key={keychain.id}
              name={keychain.name}
              description={keychain.description}
              numKeys={keychain.numKeys}
              isPublic={keychain.isPublic}
              remove={{ text: `Remove`, handler: () => removeKeychain(keychain.id) }}
            />
          ))}
          <button
            className="mt-5 text-violet-700 font-medium px-7 py-2 rounded-lg hover:bg-violet-100 self-end transition duration-100"
            onClick={onAddKeychainClicked}
          >
            <i className="fa fa-plus mr-2" />
            Add keychain
          </button>
        </div>
        <div className="flex mt-5 justify-end border-t-2 pt-8 space-x-5">
          {!isNew && (
            <Button
              type="button"
              onClick={deleteUser.start}
              color="secondary-warning"
              small
            >
              Delete user
            </Button>
          )}
          <Button
            small
            type="button"
            disabled={saveButtonDisabled}
            onClick={onSave}
            color="primary-violet"
          >
            Save user
          </Button>
        </div>
      </div>
    </div>
  </div>
);

export default EditUser;
