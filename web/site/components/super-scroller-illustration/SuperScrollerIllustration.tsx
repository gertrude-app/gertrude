import React, { useEffect, useState } from 'react';
import cx from 'classnames';
import { Logo } from '@shared/components';
import { compareTo, initializeStep, type Step } from './utils';
import Computer from './Computer';
import ComputerScreen from './ComputerScreen';
import Phone from './Phone';
import PhoneScreen from './PhoneScreen';
import Envelope from './Envelope';

interface Props {
  step: number;
}

const SuperScrollerIllustration: React.FC<Props> = ({ step }) => {
  const [currentStep, setCurrentStep] = useState<Step>(initializeStep(step));
  const hasHappened = compareTo(currentStep);

  useEffect(() => {
    const timeouts: NodeJS.Timeout[] = [];

    function scheduleEvent(stepInQuestion: Step, delay: number): void {
      timeouts.push(
        setTimeout(() => {
          setCurrentStep(stepInQuestion);
        }, delay),
      );
    }

    switch (step) {
      case 1:
        setCurrentStep(`1-0_start`);
        scheduleEvent(`1-1_openLoginScreen`, 200);
        scheduleEvent(`1-2_logIn`, 2400);
        break;
      case 2:
        setCurrentStep(`2-0_start`);
        scheduleEvent(`2-1_openMac`, 200);
        scheduleEvent(`2-2_clickDownloadButton`, 2500);
        break;
      case 3:
        setCurrentStep(`3-0_start`);
        break;
      case 4:
        setCurrentStep(`4-0_start`);
        scheduleEvent(`4-1_clickUnlockRequest`, 1500);
        break;
      case 5:
        setCurrentStep(`5-0_start`);
        scheduleEvent(`5-1_clickNotification`, 500);
        scheduleEvent(`5-2_clickAcceptRequest`, 2200);
        break;
      case 6:
        setCurrentStep(`6-0_start`);
        break;
    }

    return () => {
      timeouts.forEach(clearTimeout);
    };
  }, [step]);

  return (
    <div className="w-152 h-152 flex justify-center items-center relative scale-50 lg:scale-75 xl:scale-100 shrink-0">
      <Logo
        className={cx(
          `absolute transition-[top,transform,opacity] duration-500 ease-in left-56 delay-[800ms]`,
          hasHappened(`2-2_clickDownloadButton`)
            ? `top-28 rotate-90`
            : `-top-[calc(50vh-150px)] opacity-0 -rotate-90`,
          step > 2 && `hidden`,
        )}
        iconOnly
        size={160}
      />
      <Phone
        className={cx(
          `absolute transition-[opacity,transform,bottom,right] duration-500`,
          {
            'opacity-0 translate-y-20 scale-90 bottom-0 right-0': step === 0,
            'opacity-100 scale-100 bottom-0 right-0': step === 1,
            'opacity-20 scale-50 bottom-40 -right-64':
              step === 2 || step === 3 || currentStep === `4-0_start`,
            'opacity-100 scale-100 bottom-0 -right-36 !duration-700 delay-700':
              (step === 4 && hasHappened(`4-1_clickUnlockRequest`)) || step === 5,
            'z-10': step >= 5,
            'scale-75 bottom-0 -right-60': step === 6,
          },
        )}
      >
        <PhoneScreen
          loginScreenOpened={hasHappened(`1-1_openLoginScreen`)}
          loggedIn={hasHappened(`1-2_logIn`)}
          notificationRecieved={step === 5}
          notificationClicked={hasHappened(`5-1_clickNotification`)}
          acceptRequestClicked={hasHappened(`5-2_clickAcceptRequest`)}
          reviewingActivity={step === 6}
        />
      </Phone>
      <Envelope
        className={cx(`ransition-[opacity,transform,top,right]`, {
          'opacity-0 top-10 right-16 scale-50': !hasHappened(`4-1_clickUnlockRequest`),
          'opacity-100 -top-36 right-16 duration-500 delay-300':
            hasHappened(`4-1_clickUnlockRequest`) && step === 4,
          'opacity-100 top-4 right-16 duration-300 ease-in': step === 5,
          hidden: step === 6,
        })}
      />
      <Computer
        className={cx(`absolute transition-[opacity,transform,top,left] duration-500`, {
          'opacity-0 scale-0 translate-y-112 top-20': step === 0 || step === 1,
          'opacity-100 scale-100 left-12 top-8':
            step === 2 || step === 3 || currentStep === `4-0_start`,
          'opacity-20 scale-50 -left-40 -top-12 delay-700 !duration-700':
            (step === 4 && hasHappened(`4-1_clickUnlockRequest`)) || step === 5,
          'scale-[80%] top-0 -left-20': step === 6,
        })}
      >
        <ComputerScreen
          macOpened={hasHappened(`2-1_openMac`)}
          downloadButtonClicked={hasHappened(`2-2_clickDownloadButton`)}
          newTabOpened={hasHappened(`3-0_start`)}
          menuBarAppOpened={hasHappened(`4-0_start`)}
          unlockRequestClicked={hasHappened(`4-1_clickUnlockRequest`)}
          unlockRequestAccepted={step === 6}
        />
      </Computer>
    </div>
  );
};

export default SuperScrollerIllustration;
