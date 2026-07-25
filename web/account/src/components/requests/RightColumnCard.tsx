import { Button, Card, HStack, Text, VStack } from '@gertrude/ui';
import { type LucideIcon, RefreshCwIcon } from 'lucide-react';
import React from 'react';
import type { ButtonLink } from '#/components/types';

interface ContentProps {
  variant?: `content`;
  children: React.ReactNode;
  title: string;
  links?: ButtonLink[];
}

interface EmptyProps {
  variant: `empty`;
  icon: LucideIcon;
  text: string;
  onRefresh: () => void;
  refreshing?: boolean;
}

type Props = ContentProps | EmptyProps;

const RightColumnCard: React.FC<Props> = (props) => {
  if (props.variant === `empty`) {
    const Icon = props.icon;

    return (
      <Card preset="big" variant="subtle" padding={0}>
        <VStack align="center" gap={2.5} className="px-4 py-5 text-center">
          <div className="rounded-xl border border-stone-200 bg-white p-2 shadow-sm shadow-stone-300/30">
            <Icon className="h-5 w-5 text-stone-500" />
          </div>
          <Text variant="bodySubtle">{props.text}</Text>
          <Button
            type="button"
            variant="ghost"
            size="small"
            icon={RefreshCwIcon}
            onClick={props.onRefresh}
            loading={props.refreshing}
          >
            Refresh
          </Button>
        </VStack>
      </Card>
    );
  }

  return (
    <Card preset="big" variant="subtle" padding={0}>
      <VStack gap={1} className="p-1.25">
        <Text variant="captionSubtleStrong" className="ml-3">
          {props.title}
        </Text>
        {props.children}
        {props.links && (
          <HStack justify="end">
            {props.links.map((link) => (
              <Button
                key={`${link.href}-${link.text}`}
                type="link"
                href={link.href}
                variant={link.variant}
                icon={link.icon}
                iconPosition={link.iconPosition}
                size="small"
              >
                {link.text}
              </Button>
            ))}
          </HStack>
        )}
      </VStack>
    </Card>
  );
};

export default RightColumnCard;
