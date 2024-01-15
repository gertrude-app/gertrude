import React, { useState, useContext } from 'react';
import ExpandableContent from '../ExpandableContent';
import * as Onboarding from '../UtilityComponents';
import OnboardingContext from '../OnboardingContext';
import assets from '../cdn-assets';
import InformationModal from '../InformationModal';
import QRCode from '../QRCode';

const GetConnectionCode: React.FC = () => {
  const [showModal, setShowModal] = useState(false);
  const { emit, currentStep } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered direction="row" className="space-x-12">
      <InformationModal open={showModal} setOpen={setShowModal}>
        <div className="flex">
          <div className="space-y-4">
            <p>
              The first time you logged in to your Gertrude parent account, you were
              instructed to create a <b>Child</b>&mdash;that is, someone who will be
              protected by Gertrude. From the parent site, you can click a button to get a
              one-time six-digit <b>connection code</b> that connects that child to this
              computer.
            </p>
            <p>
              Aim your phone’s camera at the QR code to navigate to the right screen to
              get this code, or to create a child if you haven’t already.
            </p>
          </div>
          <QRCode url="gertrude.app/a-c" />
        </div>
      </InformationModal>
      <div className="!ml-0">
        <Onboarding.Heading>Get Connection Code</Onboarding.Heading>
        <Onboarding.Text className="mt-4 mb-6 max-w-2xl">
          On your <b>phone,</b> open the Gertrude parents website at{` `}
          <span className="text-pink-500 font-medium">https://parents.gertrude.app</span>,
          and select the child you want to connect to. Then, click the{` `}
          <b>Get Connection Code</b> button.
        </Onboarding.Text>
        <Onboarding.ButtonGroup
          primary="Got it, next"
          secondary={{
            text: `Help, I’m stuck...`,
            onClick: () => {
              setShowModal(true);
              emit({
                case: `infoModalOpened`,
                step: `getChildConnectionCode`,
                detail: `helpStuck`,
              });
            },
          }}
        />
      </div>
      <ExpandableContent
        asset={assets.video(
          `get-connection-code`,
          currentStep === `getChildConnectionCode`,
        )}
        width={640 * 0.6}
        height={360 * 0.6}
      />
    </Onboarding.Centered>
  );
};

export default GetConnectionCode;
