'use client';

import Image from 'next/image';
import cx from 'classnames';
import React, { useEffect, useState } from 'react';
import type { StaticImageData } from 'next/image';
import { useIntersectionObserver } from '../lib/hooks';
import Waves from '../public/wavy-bg.svg';

import LockAndChain from '../public/feature-cards/lock-and-chain.gif';
import StaticLockAndChain from '../public/feature-cards/lock-and-chain-final.png';
import Bell from '../public/feature-cards/bell.gif';
import StaticBell from '../public/feature-cards/bell-final.png';
import Family from '../public/feature-cards/family.gif';
import StaticFamily from '../public/feature-cards/family-final.png';
import StopWatch from '../public/feature-cards/stopwatch.gif';
import StaticStopWatch from '../public/feature-cards/stopwatch-final.png';
import Phone from '../public/feature-cards/phone.gif';
import StaticPhone from '../public/feature-cards/phone-final.png';

const FeaturesBlock: React.FC = () => {
  const [currentStep, setCurrentStep] = useState(0);

  const { ref: firstStepRef, intersected: firstStepIntersected } =
    useIntersectionObserver({ threshold: 1 });
  const { ref: secondStepRef, intersected: secondStepIntersected } =
    useIntersectionObserver({ threshold: 1 });
  const { ref: thirdStepRef, intersected: thirdStepIntersected } =
    useIntersectionObserver({ threshold: 1 });
  const { ref: fourthStepRef, intersected: fourthStepIntersected } =
    useIntersectionObserver({ threshold: 1 });
  const { ref: fifthStepRef, intersected: fifthStepIntersected } =
    useIntersectionObserver({ threshold: 1 });

  useEffect(() => {
    if (firstStepIntersected) setCurrentStep(1);
    if (secondStepIntersected) setCurrentStep(2);
    if (thirdStepIntersected) setCurrentStep(3);
    if (fourthStepIntersected) setCurrentStep(4);
    if (fifthStepIntersected) setCurrentStep(5);
  }, [
    firstStepIntersected,
    secondStepIntersected,
    thirdStepIntersected,
    fourthStepIntersected,
    fifthStepIntersected,
  ]);

  return (
    <section className="relative">
      <div className="w-full h-screen sticky top-0 flex flex-col justify-center items-center bg-white [perspective:1000px] overflow-hidden">
        <div className="flex-grow" />
        <Image src={Waves} alt="Waves" className="w-full" />
        <div className="flex-grow-[3] bg-gradient-to-b from-violet-300 to-violet-100 self-stretch" />
        <Feature
          title="Take complete control"
          description="Choose exactly where your kids are allowed online, and make sure they can't go anywhere else. No other mac internet filter allows the same level of strict control."
          step={1}
          currentStep={currentStep}
          gif={LockAndChain}
          png={StaticLockAndChain}
          duration={2000}
          highlightTime={1700}
        />
        <Feature
          title="Manage on the go"
          description="Add or remove sites from your own personal safelist from your phone or computer, wherever you are."
          step={2}
          currentStep={currentStep}
          gif={Phone}
          png={StaticPhone}
          duration={2000}
          highlightTime={1800}
        />
        <Feature
          title="Get notified"
          description="Get text, email, or Slack messages when your kid needs access to a blocked site or requests a temporary suspension of the mac internet blocker."
          step={3}
          currentStep={currentStep}
          gif={Bell}
          png={StaticBell}
          duration={1000}
          highlightTime={700}
        />
        <Feature
          title="Suspend the filter"
          description="Temporarily allow the whole internet, while recording screenshots of their activity and everything they type with a built-in mac keylogger."
          step={4}
          currentStep={currentStep}
          gif={StopWatch}
          png={StaticStopWatch}
          duration={1600}
          highlightTime={1800}
        />
        <Feature
          title="Protect the whole family"
          description="Manage all your kids with one account, sharing lists of safelisted sites when it makes sense. Only $5/month for the whole family."
          step={5}
          currentStep={currentStep}
          gif={Family}
          png={StaticFamily}
          duration={5000}
          highlightTime={3400}
        />
      </div>
      <div className="flex flex-col items-center gap-176 relative -mt-[100vh] py-152">
        <div ref={firstStepRef} />
        <div ref={secondStepRef} />
        <div ref={thirdStepRef} />
        <div ref={fourthStepRef} />
        <div ref={fifthStepRef} />
      </div>
    </section>
  );
};

export default FeaturesBlock;

interface FeatureProps {
  title: string;
  description: string;
  step: number;
  currentStep: number;
  gif: StaticImageData | string;
  png: StaticImageData | string;
  duration: number; // milliseconds
  highlightTime: number; // milliseconds
}

const Feature: React.FC<FeatureProps> = ({
  title,
  description,
  step,
  currentStep,
  gif,
  png,
  duration,
  highlightTime,
}) => {
  const [shown, setShown] = useState(false);
  const [animationStopped, setAnimationStopped] = useState(false);
  const [hasAppeared, setHasAppeared] = useState(false);
  const [highlighted, setHighlighted] = useState(false);

  useEffect(() => {
    if (step <= currentStep) {
      setHasAppeared(true);
      var id1 = setTimeout(() => {
        setShown(true);
      }, 500);
      var id2 = setTimeout(() => {
        setAnimationStopped(true);
      }, duration + 500);
      var id3 = setTimeout(() => {
        setHighlighted(true);
      }, highlightTime);
    }
    return () => {
      clearTimeout(id1);
      clearTimeout(id2);
      clearTimeout(id3);
    };
  }, [currentStep, step, duration, highlightTime]);

  return (
    <div
      className={cx(
        `absolute bg-white w-96 rounded-3xl transition-[transform,opacity,filter] duration-500 overflow-hidden`,
        {
          'opacity-0 [transform:translateX(calc(-230*4px))_translateZ(-800px)_rotateY(-50deg)] blur':
            step < currentStep - 1,
          'opacity-50 [transform:translateX(calc(-60*4px))_scale(50%)_rotateY(-45deg)] sm:[transform:translateX(calc(-72*4px))_scale(75%)_rotateY(-45deg)] md:[transform:translateX(calc(-96*4px))_scale(75%)_rotateY(-35deg)]':
            step === currentStep - 1,
          'opacity-100 [transform:translateZ(0px)_scale(85%)] sm:[transform:translateZ(0px)] md:[transform:translateZ(100px)]':
            step === currentStep,
          'opacity-50 [transform:translateX(calc(60*4px))_scale(50%)_rotateY(45deg)] sm:[transform:translateX(calc(70*4px))_scale(75%)_rotateY(45deg)] md:[transform:translateX(calc(96*4px))_scale(75%)_rotateY(35deg)]':
            step === currentStep + 1,
          'opacity-0 [transform:translateX(calc(230*4px))_translateZ(-800px)_rotateY(50deg)] blur':
            step > currentStep + 1,
        },
      )}
    >
      <div className="h-64 bg-white rounded-t-3xl relative flex justify-center items-center">
        <div
          className={cx(
            `bg-violet-100 rounded-full transition-[opacity,width,height] duration-500 ease-out shrink-0`,
            highlighted ? `w-128 h-128 opacity-0` : `w-0 h-0`,
          )}
        />
        {hasAppeared && (
          <div
            className={cx(
              `w-[464px] absolute -top-10 -left-10 transition-opacity duration-500 flex justify-center items-center`,
              shown ? `opacity-100` : `opacity-0`,
            )}
          >
            <Image
              src={png}
              alt=""
              className={cx(
                `w-full h-full object-center object-cover z-0`,
                animationStopped ? `relative` : `absolute`,
              )}
              priority
            />
            {!animationStopped && (
              <div className="bg-white relative z-10 w-full h-full flex justify-center items-center">
                <div
                  className={cx(
                    `bg-violet-100 rounded-full transition-[opacity,width,height] duration-500 ease-out shrink-0 absolute`,
                    highlighted ? `w-128 h-128 opacity-0` : `w-0 h-0`,
                  )}
                />
                <Image
                  src={gif}
                  alt=""
                  className="w-full h-full object-center object-cover relative"
                  priority
                />
              </div>
            )}
          </div>
        )}
      </div>
      <div className="flex flex-col items-center p-8">
        <h3 className="font-axiforma text-2xl font-semibold text-slate-900">{title}</h3>
        <p className="mt-2 text-slate-500 text-center">{description}</p>
      </div>
    </div>
  );
};
