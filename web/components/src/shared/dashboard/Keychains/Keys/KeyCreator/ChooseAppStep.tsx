import React from 'react';
import Combobox from '../../../Combobox';
import RadioGroup from '../../../RadioGroup';
import TextInput from '../../../TextInput';
import KeyCreationStep from './KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';
import * as EditKey from '../../../lib/keys/edit';

interface Props {
  keyType: 'app' | 'website';
  mode: 'edit' | 'create';
  activeStep: EditKey.Step;
  appIdentificationType: 'bundleId' | 'slug';
  appSlug?: string;
  appBundleId?: string;
  apps: Array<{ slug: string; name: string }>;
  update(event: EditKey.Event): unknown;
}

const ChooseAppStep: React.FC<Props> = (props) => {
  const {
    mode,
    keyType,
    activeStep,
    appIdentificationType,
    apps,
    appSlug,
    appBundleId,
    update,
  } = props;

  return (
    <KeyCreationStep
      mode={mode}
      update={update}
      canAdvance={canAdvance({ appIdentificationType, appSlug, appBundleId })}
      setCurrentStep={() => {}}
      lookaheadTitle="Select app"
      activeTitle="Select app:"
      title={<Title {...props} />}
      activeStep={activeStep}
      ownStep={
        keyType === `app`
          ? EditKey.Step.AppKey_ChooseApp
          : EditKey.Step.WebsiteKey_Advanced_ChooseApp
      }
    >
      <div>
        <RadioGroup<'bundleId' | 'slug'>
          options={[
            { value: `slug`, display: `Choose from common apps` },
            { value: `bundleId`, display: `By bundle ID` },
          ]}
          selectedOption={appIdentificationType}
          setSelectedOption={(to) => update({ type: `setAppIdentificationType`, to })}
          className="mb-4 -mt-5"
        />
        {appIdentificationType === `slug` ? (
          <div>
            <label className="text-gray-600 font-bold">Type application name:</label>
            <Combobox
              options={apps.map((app) => ({
                value: app.slug,
                display: app.name,
              }))}
              selected={selectedApp({ appSlug, apps })}
              setSelected={(slug) => update({ type: `setAppSlug`, to: slug })}
            />
          </div>
        ) : (
          <TextInput
            type="text"
            label="App bundle ID:"
            value={appBundleId ?? ``}
            setValue={(id) => update({ type: `setAppBundleId`, to: id })}
          />
        )}
      </div>
    </KeyCreationStep>
  );
};

export default ChooseAppStep;

function selectedApp({ apps, appSlug }: Pick<Props, 'apps' | 'appSlug'>): {
  value: string;
  display: string;
} {
  const app = apps.find((app) => app.slug === appSlug);
  if (app) {
    return { value: app.slug, display: app.name };
  }
  return { value: ``, display: `` };
}

function canAdvance(
  props: Pick<Props, 'appIdentificationType' | 'appSlug' | 'appBundleId'>,
): boolean {
  if (props.appIdentificationType === `slug`) {
    return !!props.appSlug;
  }
  return !!props.appBundleId;
}

const Title: React.FC<Props> = ({
  keyType,
  apps,
  appBundleId,
  appSlug,
  appIdentificationType,
}) => {
  return (
    <h2 className="font-medium text-gray-900 text-lg">
      <GradientIcon
        icon={appIdentificationType === `bundleId` ? `pen-to-square` : `app-store`}
        className="mr-2.5"
      />
      {keyType === `app` ? `Allowing app ` : `App `}
      {appIdentificationType === `bundleId` ? `with id` : ``}
      <UserInputText>
        {appIdentificationType === `bundleId`
          ? appBundleId
          : apps.find((app) => app.slug === appSlug)?.name ?? ``}
      </UserInputText>
    </h2>
  );
};
