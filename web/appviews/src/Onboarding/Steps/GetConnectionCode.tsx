import React from 'react';
import ExpandableImage from '../ExpandableImage';
import * as Onboarding from '../UtilityComponents';

const GetConnectionCode: React.FC = () => (
  <Onboarding.Centered direction="row" className="gap-12">
    <div>
      <Onboarding.Heading>Get Connection Code</Onboarding.Heading>
      <Onboarding.Text className="mt-4 mb-6 max-w-2xl">
        On your <b>phone,</b> open the Gertrude parents website at{` `}
        <span className="text-pink-500 font-medium">https://parents.gertrude.app</span>,
        and select the child you want to connect to. Then, click the{` `}
        <b>Get Connection Code</b> button.
      </Onboarding.Text>
      <Onboarding.ButtonGroup
        primary="Got it, next"
        secondary={{ text: `Help, I’m stuck...` }}
      />
    </div>
    <ExpandableImage
      fileName="get-connection-code.png"
      alt="Get connection code"
      width={682 / 2}
      height={443 / 2}
    />
  </Onboarding.Centered>
);

export default GetConnectionCode;
