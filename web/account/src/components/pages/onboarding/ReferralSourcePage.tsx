import { Button, HStack, Input, Text, VStack } from '@gertrude/ui';
import {
  ArrowRightIcon,
  BotIcon,
  ChevronRightIcon,
  ChurchIcon,
  type LucideIcon,
  MessageSquareMoreIcon,
  NewspaperIcon,
  SearchIcon,
  Share2Icon,
  SmartphoneIcon,
  UsersIcon,
} from 'lucide-react';
import React from 'react';
import type { ReferralSource } from '@shared/pairql/src/account';
import OnboardingScreen from '#/components/onboarding/OnboardingScreen';

const sources: {
  id: Exclude<ReferralSource, `other`>;
  label: string;
  icon: LucideIcon;
}[] = [
  { id: `friend_family`, label: `A friend or family member`, icon: UsersIcon },
  {
    id: `community_group`,
    label: `Church, homeschool, or community group`,
    icon: ChurchIcon,
  },
  { id: `search_engine`, label: `Search engine (Google, etc.)`, icon: SearchIcon },
  {
    id: `ai_chat`,
    label: `AI chat (ChatGPT, Claude, Gemini, Grok, etc.)`,
    icon: BotIcon,
  },
  { id: `app_store`, label: `App Store`, icon: SmartphoneIcon },
  {
    id: `social_media`,
    label: `Social media (Reddit, YouTube, Facebook, etc.)`,
    icon: Share2Icon,
  },
  { id: `article_news`, label: `A blog, article, or the news`, icon: NewspaperIcon },
];

interface Props {
  otherText: string | null;
  onOtherTextChange: (text: string | null) => void;
  onChoose: (source: Exclude<ReferralSource, `other`>) => void;
  onSubmitOther: () => void;
  onSkip: () => void;
}

const SourceButton: React.FC<{
  icon: LucideIcon;
  label: string;
  onClick: () => void;
  trackConversion?: boolean;
}> = ({ icon: Icon, label, onClick, trackConversion = false }) => (
  <button
    type="button"
    data-track-conversion={trackConversion ? true : undefined}
    onClick={onClick}
    className="flex w-full cursor-pointer items-center gap-3.5 rounded-2xl border border-stone-200 bg-white px-4 py-3.5 text-left shadow-sm shadow-stone-300/30 transition-[border-color,background-color,scale] duration-100 outline-none hover:border-stone-300 hover:bg-stone-50 focus-visible:ring-2 focus-visible:ring-violet-300 active:scale-[0.99]"
  >
    <Icon aria-hidden="true" className="size-5 shrink-0 text-stone-500" />
    <Text as="span" variant="bodyLargeStrong" className="min-w-0 flex-grow">
      {label}
    </Text>
    <ChevronRightIcon aria-hidden="true" className="size-4 shrink-0 text-stone-400" />
  </button>
);

const ReferralSourcePage: React.FC<Props> = ({
  otherText,
  onOtherTextChange,
  onChoose,
  onSubmitOther,
  onSkip,
}) => (
  <OnboardingScreen contentClassName="max-w-xl">
    <VStack align="center" gap={3} className="mb-7 text-center">
      <Text
        as="h1"
        variant="display"
        className="text-2xl leading-tight @2xl/main:text-3xl"
      >
        How did you hear about us?
      </Text>
    </VStack>
    <VStack gap={2.5}>
      {sources.map((source) => (
        <SourceButton
          key={source.id}
          icon={source.icon}
          label={source.label}
          trackConversion
          onClick={() => onChoose(source.id)}
        />
      ))}
      {otherText === null ? (
        <SourceButton
          icon={MessageSquareMoreIcon}
          label="Something else"
          onClick={() => onOtherTextChange(``)}
        />
      ) : (
        <form
          className="rounded-2xl border border-stone-200 bg-white shadow-sm shadow-stone-300/30"
          onSubmit={(event) => {
            event.preventDefault();
            onSubmitOther();
          }}
        >
          <HStack gap={3.5} className="px-4 pt-3.5 pb-3">
            <MessageSquareMoreIcon
              aria-hidden="true"
              className="size-5 shrink-0 text-stone-500"
            />
            <Text as="span" variant="bodyLargeStrong">
              Something else
            </Text>
          </HStack>
          <HStack gap={2.5} className="px-4 pb-4">
            <Input
              type="text"
              ariaLabel="Where did you hear about Gertrude?"
              placeholder="Where did you hear about Gertrude?"
              value={otherText}
              setValue={onOtherTextChange}
              autoFocus
              className="min-w-0 flex-grow"
            />
            <Button
              type="submit"
              data-track-conversion
              variant="primary"
              icon={ArrowRightIcon}
              iconPosition="right"
              className="shrink-0"
            >
              Continue
            </Button>
          </HStack>
        </form>
      )}
    </VStack>
    <HStack justify="center" className="mt-6">
      <Button type="button" variant="ghost" onClick={onSkip}>
        Skip
      </Button>
    </HStack>
  </OnboardingScreen>
);

export default ReferralSourcePage;
