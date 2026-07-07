import { Badge, HStack, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, CircleQuestionMarkIcon } from 'lucide-react';
import React from 'react';

interface Props {
  title: string;
  shortDescription: string;
  longExplanation: string;
  blocked: boolean;
  setBlocked: (blocked: boolean) => void;
}

const BlockGroup: React.FC<Props> = ({
  title,
  shortDescription,
  longExplanation,
  blocked,
  setBlocked,
}) => {
  const [expanded, setExpanded] = React.useState(false);

  return (
    <VStack
      className="border-t first:border-t-0 border-stone-200 py-3 px-4 hover:bg-stone-50 cursor-pointer"
      onClick={() => setBlocked(!blocked)}
    >
      <HStack justify="between" gap={2}>
        <HStack gap={4}>
          <HStack
            justify="center"
            className={cx(
              `w-5 h-5 rounded-full border shrink-0`,
              blocked ? `bg-violet-500 border-violet-500` : `bg-white border-stone-200`,
            )}
          >
            <CheckIcon
              className="w-3.5 h-3.5 text-white translate-y-[0.5px]"
              strokeWidth={3}
            />
          </HStack>
          <VStack>
            <HStack gap={2}>
              <Text variant="bodyLarge">{title}</Text>
              <Badge size="small" color={blocked ? `violet` : `neutral`}>
                {blocked ? `Blocked` : `Not Blocked`}
              </Badge>
            </HStack>
            <Text variant="bodySubtle">{shortDescription}</Text>
          </VStack>
        </HStack>
        <button
          type="button"
          aria-label={`About ${title}`}
          className="hover:bg-stone-200/50 w-7 h-7 flex justify-center items-center rounded-full cursor-pointer group"
          onClick={(event) => {
            event.stopPropagation();
            setExpanded(!expanded);
          }}
        >
          <CircleQuestionMarkIcon className="text-stone-400 w-5 h-5 group-hover:text-stone-500" />
        </button>
      </HStack>
      <div
        className={cx(
          `overflow-hidden transition-[height,opacity] duration-100`,
          expanded ? `h-auto opacity-100` : `h-0 opacity-0`,
        )}
      >
        <Text as="p" variant="bodyMuted" className="ml-9 mt-2">
          {longExplanation}
        </Text>
      </div>
    </VStack>
  );
};

export default BlockGroup;
