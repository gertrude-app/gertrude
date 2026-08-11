import { Badge, Button, EmptyState, HStack, Text, VStack } from '@gertrude/ui';
import { BanIcon, PencilIcon, PlusIcon, XIcon } from 'lucide-react';
import React from 'react';
import type { BlockRule, CustomAlwaysBlockedRule } from '#/components/types';
import AddBlockedDomainModal from './AddBlockedDomainModal';

type Props = {
  rules: CustomAlwaysBlockedRule[];
  onChange: (rules: CustomAlwaysBlockedRule[]) => void;
};

type RulePresentation = {
  type: `App` | `URL`;
  value: string;
  hasMore: boolean;
};

const addressValue = (rule: BlockRule): string | undefined => {
  switch (rule.case) {
    case `targetContains`:
    case `hostnameContains`:
    case `hostnameEquals`:
    case `hostnameEndsWith`:
    case `hostnameOrSubdomain`:
    case `urlContains`:
      return rule.value;
    default:
      return undefined;
  }
};

const presentRule = (rule: BlockRule): RulePresentation | undefined => {
  switch (rule.case) {
    case `bundleIdContains`:
      return { type: `App`, value: rule.value, hasMore: false };
    case `targetContains`:
    case `hostnameContains`:
    case `hostnameEquals`:
    case `hostnameEndsWith`:
    case `hostnameOrSubdomain`:
    case `urlContains`:
      return { type: `URL`, value: rule.value, hasMore: false };
    case `both`: {
      if (rule.a.case === `bundleIdContains`) {
        if (
          addressValue(rule.b) !== undefined ||
          (rule.b.case === `flowTypeIs` && rule.b.value === `browser`)
        ) {
          return { type: `App`, value: rule.a.value, hasMore: true };
        }
      }
      const value = addressValue(rule.a);
      if (
        value !== undefined &&
        rule.b.case === `flowTypeIs` &&
        rule.b.value === `browser`
      ) {
        return { type: `URL`, value, hasMore: true };
      }
      return undefined;
    }
    case `unless`:
      if (
        rule.rule.case === `bundleIdContains` &&
        rule.negatedBy.every((negatedRule) => addressValue(negatedRule) !== undefined)
      ) {
        return { type: `App`, value: rule.rule.value, hasMore: true };
      }
      return undefined;
    case `flowTypeIs`:
      return undefined;
  }
};

const CustomAlwaysBlockedRules: React.FC<Props> = ({ rules, onChange }) => {
  const [editor, setEditor] = React.useState<{ id?: string } | null>(null);
  const editingRule = editor?.id
    ? rules.find((rule) => rule.id === editor.id)
    : undefined;
  const visibleRules = rules.flatMap((rule) => {
    const presentation = presentRule(rule.rule);
    return presentation ? [{ rule, presentation }] : [];
  });

  const saveDomain = (domain: string): void => {
    onChange(
      editor?.id
        ? rules.map((entry) =>
            entry.id === editor.id
              ? { ...entry, rule: { case: `hostnameOrSubdomain`, value: domain } }
              : entry,
          )
        : [
            ...rules,
            {
              id: crypto.randomUUID(),
              rule: { case: `hostnameOrSubdomain`, value: domain },
            },
          ],
    );
    setEditor(null);
  };

  return (
    <>
      {visibleRules.length > 0 ? (
        <VStack gap={3}>
          <HStack wrap gap={2}>
            {visibleRules.map(({ rule, presentation }) => {
              const editable = rule.rule.case === `hostnameOrSubdomain`;
              return (
                <HStack
                  key={rule.id}
                  gap={2}
                  className="rounded-xl border border-stone-200 bg-white p-1 pl-2.5 shadow shadow-stone-300/30"
                >
                  <BanIcon className="h-4 w-4 shrink-0 text-stone-500" />
                  {presentation.type === `App` && <Badge size="xsmall">App</Badge>}
                  <Text variant="body">{presentation.value}</Text>
                  {presentation.hasMore && (
                    <Badge size="xsmall" color="violet">
                      Advanced
                    </Badge>
                  )}
                  <HStack gap={0}>
                    {editable && (
                      <Button
                        type="button"
                        onClick={() => setEditor({ id: rule.id })}
                        icon={PencilIcon}
                        ariaLabel={`Edit ${presentation.value}`}
                        size="small"
                        variant="ghost"
                      />
                    )}
                    <Button
                      type="button"
                      onClick={() =>
                        onChange(rules.filter((entry) => entry.id !== rule.id))
                      }
                      icon={XIcon}
                      ariaLabel={`Remove ${presentation.value}`}
                      size="small"
                      variant="ghost"
                    />
                  </HStack>
                </HStack>
              );
            })}
          </HStack>
          <HStack justify="end">
            <Button type="button" onClick={() => setEditor({})} icon={PlusIcon}>
              Add Blocked Domain
            </Button>
          </HStack>
        </VStack>
      ) : (
        <EmptyState
          icon={BanIcon}
          title="No Always Blocked Rules"
          description="Add a domain that should remain blocked at all times."
          button={{
            text: `Add Blocked Domain`,
            type: `button`,
            onClick: () => setEditor({}),
            icon: PlusIcon,
            variant: `primary`,
          }}
        />
      )}
      <AddBlockedDomainModal
        open={editor !== null}
        onOpenChange={(open) => {
          if (!open) {
            setEditor(null);
          }
        }}
        initialDomain={
          editingRule?.rule.case === `hostnameOrSubdomain`
            ? editingRule.rule.value
            : undefined
        }
        onAdd={saveDomain}
      />
    </>
  );
};

export default CustomAlwaysBlockedRules;
