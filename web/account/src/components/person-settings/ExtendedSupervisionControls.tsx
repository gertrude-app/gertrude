import { Badge, Button, Card, HStack, Input, Text, Toggle, VStack } from '@gertrude/ui';
import {
  EXTENDED_RESTRICTION_GROUPS,
  SOFTWARE_UPDATE_DELAY_DEFAULT,
  SOFTWARE_UPDATE_DELAY_MAX,
  SOFTWARE_UPDATE_DELAY_MIN,
  clampSoftwareUpdateDelay,
  controlOffValues,
  controlOnValues,
  groupValues,
  isControlOn,
} from '@shared/pairql/supervision';
import { ChevronDownIcon, Trash2Icon } from 'lucide-react';
import React from 'react';
import type { ExtendedControlsDraft } from '#/components/pages/person-settings/IosSettingsPage.reducer';
import type { RestrictionControl, RestrictionGroup } from '@shared/pairql/supervision';
import SettingsRow from './SettingsRow';

interface RestrictionProps {
  draft: ExtendedControlsDraft;
  onChange: (values: Partial<ExtendedControlsDraft>) => void;
}

interface Props extends RestrictionProps {
  deviceType: `iPhone` | `iPad`;
}

interface ApprovedEntry {
  value: string;
  title?: string;
}

const ApprovedListEditor: React.FC<{
  type: `apps` | `websites`;
  entries: ApprovedEntry[];
  onAdd: (value: string, title: string) => void;
  onRemove: (value: string) => void;
}> = ({ type, entries, onAdd, onRemove }) => {
  const [newValue, setNewValue] = React.useState(``);
  const [newTitle, setNewTitle] = React.useState(``);
  const isWebsite = type === `websites`;
  const value = newValue.trim();
  const title = newTitle.trim();
  const duplicate = entries.some((entry) => entry.value === value);
  const canAdd = !!value && !duplicate && (!isWebsite || !!title);
  const add = (): void => {
    if (!canAdd) return;
    onAdd(value, title);
    setNewValue(``);
    setNewTitle(``);
  };

  return (
    <VStack gap={3} className="mt-3">
      {entries.length > 0 && (
        <Card padding={0} className="overflow-hidden">
          {entries.map((entry) => (
            <HStack
              key={entry.value}
              justify="between"
              gap={3}
              className="p-3 border-t first:border-t-0 border-stone-200"
            >
              <VStack className="min-w-0">
                {entry.title && <Text variant="bodyStrong">{entry.title}</Text>}
                <Text variant="bodySubtle" className="font-mono break-all">
                  {entry.value}
                </Text>
              </VStack>
              <Button
                type="button"
                variant="ghost"
                icon={Trash2Icon}
                ariaLabel={`Remove ${entry.title ?? entry.value}`}
                onClick={() => onRemove(entry.value)}
              />
            </HStack>
          ))}
        </Card>
      )}
      <div
        className={isWebsite ? `flex flex-col @lg/main:flex-row gap-2` : `flex gap-2`}
        onKeyDown={(event) => {
          if (event.key === `Enter` && event.target instanceof HTMLInputElement) {
            event.preventDefault();
            add();
          }
        }}
      >
        {isWebsite && (
          <Input
            type="text"
            ariaLabel="Name (e.g. Weather)"
            placeholder="Name (e.g. Weather)"
            value={newTitle}
            setValue={setNewTitle}
            className="@lg/main:w-44 shrink-0"
          />
        )}
        <Input
          type="text"
          ariaLabel={
            isWebsite
              ? `URL (e.g. https://weather.com)`
              : `App bundle ID (e.g. com.apple.mobilesafari)`
          }
          placeholder={
            isWebsite
              ? `URL (e.g. https://weather.com)`
              : `App bundle ID (e.g. com.apple.mobilesafari)`
          }
          value={newValue}
          setValue={setNewValue}
          className="flex-1 min-w-0"
        />
        <Button type="button" disabled={!canAdd} onClick={add} className="shrink-0">
          {isWebsite ? `Add website` : `Add app`}
        </Button>
      </div>
    </VStack>
  );
};

const RestrictionRow: React.FC<RestrictionProps & { control: RestrictionControl }> = ({
  control,
  draft,
  onChange,
}) => {
  const on = isControlOn(draft, control);
  return (
    <VStack gap={2} className="p-3 border-t border-stone-200">
      <HStack justify="between" gap={4}>
        <VStack>
          <Text variant="bodyStrong">{control.label}</Text>
          {control.hint && <Text variant="bodySubtle">{control.hint}</Text>}
        </VStack>
        <HStack gap={2}>
          <Badge size="small" color={on ? `violet` : `neutral`}>
            {on ? (control.onWord ?? `Blocked`) : (control.offWord ?? `Allowed`)}
          </Badge>
          <Toggle
            small
            checked={on}
            ariaLabel={control.label}
            setChecked={(checked) =>
              onChange(checked ? controlOnValues(control) : controlOffValues(control))
            }
          />
        </HStack>
      </HStack>
      {control.delayDays && on && (
        <HStack gap={2}>
          <Text variant="bodySubtle">Delay for</Text>
          <Input
            type="number"
            ariaLabel="Delay for"
            min={SOFTWARE_UPDATE_DELAY_MIN}
            max={SOFTWARE_UPDATE_DELAY_MAX}
            value={String(
              draft.enforcedSoftwareUpdateDelay ?? SOFTWARE_UPDATE_DELAY_DEFAULT,
            )}
            setValue={(value) =>
              onChange({ enforcedSoftwareUpdateDelay: clampSoftwareUpdateDelay(value) })
            }
            className="w-20"
          />
          <Text variant="bodySubtle">days after release</Text>
        </HStack>
      )}
    </VStack>
  );
};

const RestrictionGroupCard: React.FC<RestrictionProps & { group: RestrictionGroup }> = ({
  group,
  draft,
  onChange,
}) => {
  const onCount = group.controls.filter((control) => isControlOn(draft, control)).length;
  const partial = onCount > 0 && onCount < group.controls.length;
  const [manualExpanded, setManualExpanded] = React.useState<boolean | undefined>();
  const expanded = manualExpanded ?? partial;
  const contentId = React.useId();

  return (
    <Card padding={0} className="overflow-hidden">
      <HStack justify="between" gap={4} className="p-3 bg-stone-50">
        <button
          type="button"
          aria-expanded={expanded}
          aria-controls={contentId}
          onClick={() => setManualExpanded(!expanded)}
          className="flex flex-1 items-start gap-3 min-w-0 text-left cursor-pointer rounded focus-visible:outline-2 focus-visible:outline-violet-400"
        >
          <ChevronDownIcon
            className={`h-5 w-5 shrink-0 mt-0.5 text-stone-400 transition-transform ${expanded ? `` : `-rotate-90`}`}
          />
          <VStack>
            <Text variant="bodyStrong">{group.title}</Text>
            <Text variant="bodySubtle">{group.description}</Text>
          </VStack>
        </button>
        <HStack gap={2}>
          {onCount > 0 && (
            <Badge size="small" color="violet">
              {onCount} of {group.controls.length}
            </Badge>
          )}
          <Toggle
            checked={onCount > 0}
            ariaLabel={`${group.title}: all restrictions`}
            setChecked={(checked) => onChange(groupValues(group, checked))}
          />
        </HStack>
      </HStack>
      <div id={contentId} hidden={!expanded}>
        {group.controls.map((control) => (
          <RestrictionRow
            key={control.field}
            control={control}
            draft={draft}
            onChange={onChange}
          />
        ))}
      </div>
    </Card>
  );
};

const ExtendedSupervisionControls: React.FC<Props> = ({
  draft,
  onChange,
  deviceType,
}) => (
  <VStack gap={3}>
    <Text variant="bodySubtle">
      Fine-grained restrictions for this supervised {deviceType}. Anything you turn on
      (purple) is enforced on the device; anything left off stays available.
    </Text>
    <SettingsRow
      type="toggle"
      title="Only allow approved apps"
      description={`Hide every app on the ${deviceType} except the ones you specifically approve.`}
      enabled={draft.whitelistedAppBundleIds !== null}
      setEnabled={(enabled) => onChange({ whitelistedAppBundleIds: enabled ? [] : null })}
      warning={`With no apps approved, nearly every app will be hidden from the ${deviceType}.`}
      showWarning={draft.whitelistedAppBundleIds?.length === 0}
      warningPosition="beforeContent"
    >
      <ApprovedListEditor
        type="apps"
        entries={(draft.whitelistedAppBundleIds ?? []).map((value) => ({ value }))}
        onAdd={(value) =>
          onChange({
            whitelistedAppBundleIds: [...(draft.whitelistedAppBundleIds ?? []), value],
          })
        }
        onRemove={(value) =>
          onChange({
            whitelistedAppBundleIds:
              draft.whitelistedAppBundleIds?.filter((bundleId) => bundleId !== value) ??
              [],
          })
        }
      />
    </SettingsRow>
    <SettingsRow
      type="toggle"
      title="Only allow approved websites"
      description={`Block every website on the ${deviceType} except the ones you specifically approve.`}
      enabled={draft.webAllowList !== null}
      setEnabled={(enabled) => onChange({ webAllowList: enabled ? [] : null })}
      warning={`With no websites approved, the entire web will be blocked on the ${deviceType}.`}
      showWarning={draft.webAllowList?.length === 0}
      warningPosition="beforeContent"
    >
      <ApprovedListEditor
        type="websites"
        entries={(draft.webAllowList ?? []).map((bookmark) => ({
          value: bookmark.url,
          title: bookmark.title,
        }))}
        onAdd={(url, title) =>
          onChange({ webAllowList: [...(draft.webAllowList ?? []), { url, title }] })
        }
        onRemove={(url) =>
          onChange({
            webAllowList:
              draft.webAllowList?.filter((bookmark) => bookmark.url !== url) ?? [],
          })
        }
      />
    </SettingsRow>
    {EXTENDED_RESTRICTION_GROUPS.map((group) => (
      <RestrictionGroupCard
        key={group.id}
        group={group}
        draft={draft}
        onChange={onChange}
      />
    ))}
  </VStack>
);

export default ExtendedSupervisionControls;
