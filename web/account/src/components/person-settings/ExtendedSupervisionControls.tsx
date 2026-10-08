import {
  Badge,
  Button,
  Card,
  HStack,
  Input,
  SelectionCircle,
  Text,
  VStack,
} from '@gertrude/ui';
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
import { Trash2Icon } from 'lucide-react';
import React from 'react';
import type { ExtendedControlsDraft } from '#/components/pages/person-settings/IosSettingsPage.reducer';
import type { RestrictionControl } from '@shared/pairql/supervision';
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
    <VStack gap={2} className="mt-2">
      {entries.length > 0 && (
        <Card padding={0} className="overflow-hidden">
          {entries.map((entry) => (
            <HStack
              key={entry.value}
              justify="between"
              gap={3}
              className="px-3 py-1 border-t first:border-t-0 border-stone-200"
            >
              <VStack className="min-w-0">
                {entry.title && <Text variant="captionStrong">{entry.title}</Text>}
                <Text variant="captionSubtle" className="font-mono break-all">
                  {entry.value}
                </Text>
              </VStack>
              <Button
                type="button"
                variant="ghost"
                size="small"
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
  const hintId = React.useId();
  return (
    <VStack className="border-t first:border-t-0 border-stone-200">
      <HStack
        as="button"
        type="button"
        role="checkbox"
        aria-checked={on}
        aria-label={control.label}
        aria-describedby={control.hint ? hintId : undefined}
        gap={3}
        className="w-full py-2 px-3 hover:bg-stone-50 cursor-pointer text-left outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-violet-400/70"
        onClick={() =>
          onChange(on ? controlOffValues(control) : controlOnValues(control))
        }
      >
        <SelectionCircle selected={on} />
        <VStack as="span" className="min-w-0">
          <HStack as="span" gap={2} wrap>
            <Text variant="body">{control.label}</Text>
            <Badge size="small" color={on ? `violet` : `neutral`}>
              {on ? (control.onWord ?? `Blocked`) : (control.offWord ?? `Allowed`)}
            </Badge>
          </HStack>
          {control.hint && (
            <Text id={hintId} variant="captionSubtle">
              {control.hint}
            </Text>
          )}
        </VStack>
      </HStack>
      {control.delayDays && on && (
        <HStack gap={2} className="ml-8 px-3 pb-2">
          <Text variant="captionSubtle" className="shrink-0">
            Delay for
          </Text>
          <Input
            type="number"
            size="small"
            ariaLabel="Delay for"
            min={SOFTWARE_UPDATE_DELAY_MIN}
            max={SOFTWARE_UPDATE_DELAY_MAX}
            value={String(
              draft.enforcedSoftwareUpdateDelay ?? SOFTWARE_UPDATE_DELAY_DEFAULT,
            )}
            setValue={(value) =>
              onChange({ enforcedSoftwareUpdateDelay: clampSoftwareUpdateDelay(value) })
            }
            className="w-16 shrink-0"
          />
          <Text variant="captionSubtle">days after release</Text>
        </HStack>
      )}
    </VStack>
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
    {EXTENDED_RESTRICTION_GROUPS.map((group) => {
      const onCount = group.controls.filter((control) =>
        isControlOn(draft, control),
      ).length;
      return (
        <SettingsRow
          key={group.id}
          type="toggle"
          title={group.title}
          description={group.description}
          enabled={onCount > 0}
          setEnabled={(enabled) => onChange(groupValues(group, enabled))}
          toggleLabel={`${group.title}: all restrictions`}
          badge={
            onCount > 0 && (
              <Badge size="small" color="violet">
                {onCount} of {group.controls.length}
              </Badge>
            )
          }
        >
          <Card padding={0} className="overflow-hidden">
            {group.controls.map((control) => (
              <RestrictionRow
                key={control.field}
                control={control}
                draft={draft}
                onChange={onChange}
              />
            ))}
          </Card>
        </SettingsRow>
      );
    })}
  </VStack>
);

export default ExtendedSupervisionControls;
