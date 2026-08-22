import { Banner, Card, HStack, Input, Select, Text, Toggle, VStack } from '@gertrude/ui';
import { GlobeIcon, NetworkIcon, RegexIcon } from 'lucide-react';
import React from 'react';
import type { DomainMatchType, KeyEditorState, KeyTargetType } from './keyEditor';
import { domainDetails, keyFromEditorState } from './keyEditor';

const targetTypeOptions = [
  {
    value: `website`,
    label: `Website address`,
    description: `Allow a domain or hostname`,
    icon: GlobeIcon,
  },
  {
    value: `ipAddress`,
    label: `IP address`,
    description: `Allow a network address`,
    icon: NetworkIcon,
  },
  {
    value: `domainRegex`,
    label: `Domain pattern`,
    description: `Match hostnames with a regular expression`,
    icon: RegexIcon,
  },
] as const;

const targetInputCopy = (
  targetType: KeyTargetType,
): { label: string; placeholder: string; helperText?: string } => {
  switch (targetType) {
    case `website`:
      return {
        label: `Website address`,
        placeholder: `example.com or https://school.example.com`,
      };
    case `ipAddress`:
      return {
        label: `IP address`,
        placeholder: `192.0.2.1`,
        helperText: `IPv4 and IPv6 addresses are supported.`,
      };
    case `domainRegex`:
      return {
        label: `Domain pattern`,
        placeholder: `^.*\\.edu$`,
        helperText: `Case-insensitive regular expression matched against the hostname only.`,
      };
  }
};

const targetStepDescription = (targetType: KeyTargetType): string => {
  switch (targetType) {
    case `website`:
      return `Paste a full URL or enter a domain. Gertrude will keep only the part used for filtering.`;
    case `ipAddress`:
      return `Enter the network address that assigned Macs should be allowed to reach.`;
    case `domainRegex`:
      return `Enter a regular expression for the hostnames this key should allow.`;
  }
};

const subdomainExamples = (state: KeyEditorState): string[] => {
  const details = domainDetails(state.address);
  if (!details) {
    return [];
  }

  const examples = details.hasSubdomain ? [details.hostname] : [];
  for (const prefix of [`images`, `api`, `docs`]) {
    const example = `${prefix}.${details.registrableDomain}`;
    if (!examples.includes(example)) {
      examples.push(example);
    }
  }
  return examples.slice(0, 3);
};

const MatchingEditor: React.FC<{
  state: KeyEditorState;
  disabled: boolean;
  changeMatching: (domainMatch: DomainMatchType) => void;
}> = ({ state, disabled, changeMatching }) => {
  const details = domainDetails(state.address);
  const includeSubdomains = state.domainMatch === `standard`;
  const examples = subdomainExamples(state);

  return (
    <Card padding={3}>
      <HStack justify="between" gap={4}>
        <VStack gap={0.5} className="min-w-0">
          <Text variant="bodyStrong">Include subdomains</Text>
          <Text variant="captionSubtle" className="leading-5">
            {`Allow any hostname underneath ${details?.registrableDomain ?? `this website`}, like `}
            {examples.map((example, index) => (
              <React.Fragment key={example}>
                {index > 0 && (index === examples.length - 1 ? `, or ` : `, `)}
                <Text as="code" variant="code" className="text-xs">
                  {example}
                </Text>
              </React.Fragment>
            ))}
            .
          </Text>
        </VStack>
        <Toggle
          checked={includeSubdomains}
          setChecked={(checked) => changeMatching(checked ? `standard` : `strict`)}
          disabled={disabled}
          ariaLabel="Include subdomains"
        />
      </HStack>
    </Card>
  );
};

type Props = {
  state: KeyEditorState;
  inputId: string;
  error: string | null;
  warning: string | null;
  disabled: boolean;
  changeTargetType: (targetType: KeyTargetType) => void;
  changeAddress: (address: string) => void;
  changeMatching: (domainMatch: DomainMatchType) => void;
};

const KeyTargetEditor: React.FC<Props> = ({
  state,
  inputId,
  error,
  warning,
  disabled,
  changeTargetType,
  changeAddress,
  changeMatching,
}) => {
  const inputCopy = targetInputCopy(state.targetType);
  const targetKey = keyFromEditorState({ ...state, scopeType: `webBrowsers` });

  return (
    <VStack gap={4}>
      <VStack gap={1}>
        <Text as="h2" variant="heading">
          What should this key allow?
        </Text>
        <Text variant="bodySubtle" className="leading-6">
          {targetStepDescription(state.targetType)}
        </Text>
      </VStack>

      <div className="grid grid-cols-1 items-start gap-2 @lg/slide:grid-cols-[minmax(0,1.25fr)_minmax(0,0.75fr)]">
        <Input
          id={inputId}
          type="text"
          label={inputCopy.label}
          value={state.address}
          setValue={changeAddress}
          placeholder={inputCopy.placeholder}
          helperText={inputCopy.helperText}
          error={error ?? undefined}
          autoComplete="off"
          disabled={disabled}
        />
        <Select
          selected={state.targetType}
          setSelected={changeTargetType}
          possibleValues={targetTypeOptions}
          disabled={disabled}
          className="min-w-0 @lg/slide:mt-[24px]"
        />
      </div>

      {state.targetType === `website` && targetKey && (
        <MatchingEditor
          state={state}
          disabled={disabled}
          changeMatching={changeMatching}
        />
      )}

      {warning && <Banner variant="warning">{warning}</Banner>}
    </VStack>
  );
};

export default KeyTargetEditor;
