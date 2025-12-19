import { Button, SelectMenu, TextInput } from '@shared/components';
import Badge from '@shared/components/src/Badge';
import React from 'react';
import type { ChildComputerStatus, ReleaseChannel } from '@dash/types';
import PageHeading from '../PageHeading';
import UserStatus from '../UserStatus';

interface Props {
  name: string;
  setName(name: string): unknown;
  releaseChannel: ReleaseChannel;
  setReleaseChannel(channel: ReleaseChannel): unknown;
  modelTitle: string;
  serialNumber: string;
  modelIdentifier: string;
  appVersion: string;
  latestReleaseVersion: string;
  users: Array<{
    name: string;
    id: string;
    status: ChildComputerStatus;
  }>;
  saveButtonDisabled: boolean;
  onSave(): unknown;
}

const EditComputer: React.FC<Props> = ({
  name,
  setName,
  releaseChannel,
  setReleaseChannel,
  modelTitle,
  serialNumber,
  modelIdentifier,
  appVersion,
  latestReleaseVersion,
  users,
  saveButtonDisabled,
  onSave,
}) => (
  <div className="">
    <PageHeading icon={`desktop`}>Edit computer</PageHeading>
    <div className="border border-slate-200 mt-8 rounded-3xl bg-white p-6 sm:p-8 pr-8 xl:pr-12 flex justify-between items-center gap-16">
      <div className="flex flex-col gap-6 xs:gap-0 lg:gap-4 flex-grow justify-between self-stretch">
        <div className="flex flex-col-reverse xs:flex-row xs:justify-between items-center xs:items-start gap-4 xs:gap-8">
          <div className="flex flex-col items-center xs:items-start lg:ml-4 text-slate-400 text-xs lg:text-sm">
            <h2 className="text-lg font-bold text-slate-900 mb-2 lg:mb-3 lg:-ml-4">
              {modelTitle}
            </h2>
            <div className="flex flex-col gap-1 lg:gap-2">
              <h3>
                Serial number:{` `}
                <span className="text-slate-600 font-medium">{serialNumber}</span>
              </h3>
              <h3>
                Model identifier:{` `}
                <span className="text-slate-600 font-medium">{modelIdentifier}</span>
              </h3>
            </div>
          </div>
          <div className="w-32 h-28 justify-center items-center lg:hidden flex">
            <img
              alt={modelTitle}
              src={`/macs/${modelIdentifier}.png`}
              className="max-w-full max-h-full"
            />
          </div>
        </div>
        <TextInput
          type="text"
          value={name}
          setValue={setName}
          placeholder="How you refer to this computer"
          label="Computer name:"
          className="max-w-xl"
          testId="computer-name-input"
        />
      </div>
      <div className="shrink-0 w-40 xl:w-52 h-40 xl:h-52 hidden lg:flex justify-center items-center bg-white">
        <img
          alt={modelTitle}
          src={`/macs/${modelIdentifier}.png`}
          className="max-w-full max-h-full"
        />
      </div>
    </div>
    <div className="border border-slate-200 mt-4 sm:mt-6 rounded-3xl bg-white p-6 sm:p-8 flex flex-col gap-6 xl:gap-2 xl:flex-row justify-between items-center">
      <div className="text-lg text-slate-600 font-medium flex flex-col-reverse xs:flex-row items-center gap-2 justify-center self-stretch">
        <div className="flex items-center gap-2">
          <span>Running:</span>
          <span className="font-bold text-slate-800 shrink-0">Gertrude {appVersion}</span>
        </div>
        {appVersion >= latestReleaseVersion ? (
          <Badge type="green" size="small" className="shrink-0">
            Up to date
          </Badge>
        ) : (
          <Badge type="yellow" size="small" className="shrink-0">
            Updates available
          </Badge>
        )}
      </div>
      <div className="flex items-center space-x-2 text-slate-500">
        <span>Release channel:</span>
        <SelectMenu<ReleaseChannel>
          options={[
            { value: `stable`, display: `Stable` },
            { value: `beta`, display: `Beta` },
            { value: `canary`, display: `Canary` },
          ]}
          size="medium"
          selectedOption={releaseChannel}
          setSelected={setReleaseChannel}
          testId="release-channel-select"
        />
      </div>
    </div>
    <div className="border border-slate-200 mt-4 sm:mt-6 rounded-3xl bg-white p-6 sm:p-8">
      <h3 className="text-xl font-bold text-slate-900">Children using this computer:</h3>
      <div className="mt-4 flex flex-col gap-2">
        {users.map((user) => (
          <UserStatus key={user.id} {...user} />
        ))}
      </div>
    </div>
    <div className="flex justify-end gap-4 mt-6 xs:mt-8">
      <Button size="large" type="link" to={`/computers`} color="tertiary">
        Cancel
      </Button>
      <Button
        size="large"
        type="button"
        onClick={onSave}
        disabled={saveButtonDisabled}
        color="primary"
      >
        Save
      </Button>
    </div>
  </div>
);

export default EditComputer;
