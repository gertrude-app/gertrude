import { Badge, HStack, SelectionCircle, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import { CircleQuestionMarkIcon } from 'lucide-react';
import React from 'react';

interface Props {
  title: string;
  shortDescription: string;
  longExplanation: string;
  blocked: boolean;
  setBlocked: (blocked: boolean) => void;
  defaultExpanded?: boolean;
}

const BlockGroup: React.FC<Props> = ({
  title,
  shortDescription,
  longExplanation,
  blocked,
  setBlocked,
  defaultExpanded = false,
}) => {
  const [expanded, setExpanded] = React.useState(defaultExpanded);

  return (
    <VStack
      className="border-t first:border-t-0 border-stone-200 py-3 px-4 hover:bg-stone-50 cursor-pointer"
      onClick={() => setBlocked(!blocked)}
    >
      <HStack justify="between" gap={2}>
        <HStack gap={4}>
          <SelectionCircle selected={blocked} />
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
