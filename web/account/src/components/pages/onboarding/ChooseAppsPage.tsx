import {
  AppIcon,
  Button,
  Card,
  HStack,
  Stack,
  Text,
  VStack,
  inflect,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  ArrowRightIcon,
  CheckIcon,
  LaptopIcon,
  SmartphoneIcon,
  TabletIcon,
} from 'lucide-react';
import React from 'react';
import { type SetupApp, setupApps } from '#/components/onboarding/setupApps';
import './ChooseAppsPage.css';

export type { SetupApp } from '#/components/onboarding/setupApps';

const question = `What would you like to set up?`;

const platforms = {
  mac: { label: `Mac`, icon: LaptopIcon },
  iphone: { label: `iPhone`, icon: SmartphoneIcon },
  ipad: { label: `iPad`, icon: TabletIcon },
};

interface Props {
  selectedApps: SetupApp[];
  onSelectedAppsChange: (apps: SetupApp[]) => void;
  onContinue: (apps: SetupApp[]) => void;
  onSkip: () => void;
}

const ChooseAppsPage: React.FC<Props> = ({
  selectedApps,
  onSelectedAppsChange,
  onContinue,
  onSkip,
}) => {
  const id = React.useId();

  return (
    <main className="@container/main relative isolate flex min-h-screen flex-col overflow-hidden bg-white px-5 py-8 sm:px-8 sm:py-10">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-x-0 bottom-0 -z-10 h-3/4 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_bottom,rgba(196,180,255,0.25)_0%,transparent_65%)] [background-position:center,bottom] [background-size:1440px_1440px,cover] [mask-image:linear-gradient(transparent,black)]"
      />
      <header className="choose-apps-brand choose-apps-reveal flex justify-center">
        <img src="/logo-wordmark.svg" alt="Gertrude" className="h-auto w-28" />
      </header>
      <div className="mx-auto flex w-full max-w-3xl flex-grow flex-col justify-center py-8 @2xl/main:py-12">
        <form
          onSubmit={(event) => {
            event.preventDefault();
            if (selectedApps.length > 0) onContinue(selectedApps);
          }}
        >
          <VStack align="center" gap={3} className="mb-7 text-center @2xl/main:mb-9">
            <Text
              as="h1"
              id={`${id}-heading`}
              aria-label={question}
              variant="display"
              className="choose-apps-question max-w-xl text-2xl leading-tight @2xl/main:text-3xl"
            >
              {question.split(` `).map((word, index) => (
                <React.Fragment key={word}>
                  {index > 0 && ` `}
                  <span
                    aria-hidden="true"
                    className="choose-apps-word"
                    style={{ animationDelay: `${80 + index * 45}ms` }}
                  >
                    {word}
                  </span>
                </React.Fragment>
              ))}
            </Text>
            <Text
              as="p"
              id={`${id}-description`}
              variant="proseSubtle"
              className="choose-apps-instructions choose-apps-reveal"
            >
              Choose one or more apps.
            </Text>
          </VStack>
          <fieldset
            aria-labelledby={`${id}-heading`}
            aria-describedby={`${id}-description`}
            className="grid min-w-0 grid-cols-1 gap-3 @2xl/main:grid-cols-2 @2xl/main:gap-4"
          >
            {setupApps.map((app, index) => {
              const selected = selectedApps.includes(app.id);

              return (
                <label
                  key={app.id}
                  className="choose-apps-option choose-apps-reveal flex cursor-pointer"
                  style={{ animationDelay: `${1400 + index * 60}ms` }}
                >
                  <input
                    type="checkbox"
                    name="setupApps"
                    value={app.id}
                    checked={selected}
                    aria-labelledby={`${id}-${app.id}-name`}
                    aria-describedby={`${id}-${app.id}-platform ${id}-${app.id}-description`}
                    onChange={(event) =>
                      onSelectedAppsChange(
                        event.target.checked
                          ? [...selectedApps, app.id]
                          : selectedApps.filter((selectedApp) => selectedApp !== app.id),
                      )
                    }
                    className="peer sr-only"
                  />
                  <Card
                    as="span"
                    preset="big"
                    padding={0}
                    interactive
                    selected={selected}
                    className="relative flex w-full flex-col overflow-hidden peer-focus-visible:ring-2 peer-focus-visible:ring-violet-400 peer-focus-visible:ring-offset-3"
                  >
                    <HStack
                      as="span"
                      gap={3}
                      className="w-full min-w-0 bg-white p-3.5 pb-3 @2xl/main:p-5 @2xl/main:pb-4"
                    >
                      <AppIcon
                        src={app.icon}
                        size="medium"
                        outlined={app.iconOutlined}
                        className="@2xl/main:size-12"
                      />
                      <Text
                        id={`${id}-${app.id}-name`}
                        variant="bodyLargeStrong"
                        className="min-w-0 flex-grow pr-6"
                      >
                        {app.name}
                      </Text>
                    </HStack>
                    <VStack
                      as="span"
                      gap={2}
                      className="min-w-0 flex-grow border-t border-stone-200 bg-stone-50 px-3.5 py-3 @2xl/main:px-5 @2xl/main:py-3.5"
                    >
                      <HStack as="span" id={`${id}-${app.id}-platform`} gap={1.5} wrap>
                        {app.platforms.map((platform) => {
                          const { label, icon: Icon } = platforms[platform];
                          return (
                            <span
                              key={platform}
                              className="inline-flex items-center gap-1 rounded-full border border-stone-200 bg-white px-2 py-0.5 text-xs leading-4 text-stone-600 shadow-xs shadow-stone-300/50"
                            >
                              <Icon aria-hidden="true" className="size-3 shrink-0" />
                              {label}
                            </span>
                          );
                        })}
                      </HStack>
                      <Text
                        id={`${id}-${app.id}-description`}
                        variant="bodySubtle"
                        className="leading-5"
                      >
                        {app.description}
                      </Text>
                    </VStack>
                    <span
                      aria-hidden="true"
                      className={cx(
                        `absolute right-3.5 top-3.5 flex h-5 w-5 items-center justify-center rounded-md border shadow-sm transition-[background-color,border-color] duration-150 @2xl/main:right-5 @2xl/main:top-5`,
                        selected
                          ? `border-violet-800 bg-violet-500 text-white shadow-violet-500/20`
                          : `border-stone-300/80 bg-white text-transparent shadow-stone-300/20`,
                      )}
                    >
                      <CheckIcon className="h-3.5 w-3.5" strokeWidth={3} />
                    </span>
                  </Card>
                </label>
              );
            })}
          </fieldset>
          <Stack
            direction={{ default: `vertical`, '@2xl/main': `horizontal` }}
            align={{ default: `stretch`, '@2xl/main': `center` }}
            justify="between"
            gap={5}
            className="mt-6 @2xl/main:mt-7"
          >
            <Text
              as="p"
              variant="bodyMuted"
              className="choose-apps-reassurance choose-apps-reveal min-w-0 text-left"
            >
              You can change your choices or add more apps later.
            </Text>
            <HStack justify="end" gap={3} className="shrink-0">
              <span className="choose-apps-skip choose-apps-reveal">
                <Button type="button" variant="default" size="large" onClick={onSkip}>
                  I’ll decide later
                </Button>
              </span>
              <span className="choose-apps-continue choose-apps-reveal">
                <Button
                  type="submit"
                  variant="primary"
                  size="large"
                  icon={ArrowRightIcon}
                  iconPosition="right"
                  disabled={selectedApps.length === 0}
                >
                  Continue
                </Button>
              </span>
            </HStack>
          </Stack>
          <span role="status" className="sr-only">
            {selectedApps.length} {inflect(`app`, selectedApps.length)} selected
          </span>
        </form>
      </div>
    </main>
  );
};

export default ChooseAppsPage;
