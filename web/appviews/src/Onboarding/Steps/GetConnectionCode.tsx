import React, { useContext, useState } from 'react';
import ExpandableContent from '../ExpandableContent';
import InformationModal from '../InformationModal';
import OnboardingContext from '../OnboardingContext';
import QRCode from '../QRCode';
import * as Onboarding from '../UtilityComponents';
import assets from '../cdn-assets';

const GetConnectionCode: React.FC = () => {
  const [showModal, setShowModal] = useState(false);
  const { emit, currentStep } = useContext(OnboardingContext);
  return (
    <Onboarding.Centered direction="row" className="space-x-12">
      <InformationModal open={showModal} onClose={() => setShowModal(false)}>
        <div className="flex">
          <div className="space-y-4">
            <p>
              Everyone protected by Gertrude is listed under <b>People</b> on the Gertrude
              account site. From there, you can get a one-time six-digit{` `}
              <b>connection code</b> that connects that person to this computer.
            </p>
            <p>
              Aim your phone’s camera at the QR code to navigate to the right screen to
              get this code, or to add a person if you haven’t already.
            </p>
          </div>
          <QRCode url="gertrude.app/a-c" />
        </div>
      </InformationModal>
      <div className="!ml-0">
        <Onboarding.Heading>Get Connection Code</Onboarding.Heading>
        <Onboarding.Text className="mt-4 mb-6 max-w-2xl">
          On your <b>phone,</b> open the Gertrude account site at{` `}
          <span className="text-pink-500 font-medium">https://account.gertrude.app</span>.
          Find the person who will use this computer, click <b>Add a device</b>, and
          choose <b>Mac</b>. Then, click the <b>Get connection code</b> button.
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
