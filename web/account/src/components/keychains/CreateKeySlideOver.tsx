import {
  Banner,
  Button,
  Card,
  DateTimePicker,
  HStack,
  SlideOver,
  Spacer,
  Text,
  Textarea,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import {
  ArrowLeftIcon,
  ArrowRightIcon,
  ClockIcon,
  FileTextIcon,
  KeyRoundIcon,
} from 'lucide-react';
import React from 'react';
import type {
  AppIdentificationType,
  KeyEditorApp,
  KeyEditorSaveData,
  KeyEditorState,
  KeyScopeType,
  KeyTargetType,
} from './keyEditor';
import { KeyDisplay } from './KeyList';
import KeyScopeEditor from './KeyScopeEditor';
import KeyTargetEditor from './KeyTargetEditor';
import {
  broadAccessWarning,
  changeKeyEditorAddress,
  changeKeyEditorDomainMatch,
  changeKeyEditorTargetType,
  keyEditorError,
  keyFromEditorState,
  newKeyEditorState,
} from './keyEditor';

type EditorStage = `target` | `scope` | `review`;

type Props = {
  open: boolean;
  apps: KeyEditorApp[];
  saving: boolean;
  onOpenChange: (open: boolean) => void;
  onSave: (data: KeyEditorSaveData) => Promise<void>;
};

const flowStages: Array<{ stage: EditorStage; label: string }> = [
  { stage: `target`, label: `Address` },
  { stage: `scope`, label: `Where it works` },
  { stage: `review`, label: `Review` },
];

const FlowProgress: React.FC<{ stage: EditorStage }> = ({ stage }) => {
  const activeIndex = flowStages.findIndex((item) => item.stage === stage);

  return (
    <div className="grid grid-cols-3 gap-2" aria-label="Key setup progress">
      {flowStages.map((item, index) => (
        <VStack key={item.stage} gap={1}>
          <div
            className={cx(
              `h-1 rounded-full transition-colors`,
              index <= activeIndex ? `bg-violet-500` : `bg-stone-200`,
            )}
          />
          <Text
            variant={index === activeIndex ? `captionStrong` : `captionMuted`}
            className={cx(index < activeIndex && `text-violet-700`)}
            aria-current={index === activeIndex ? `step` : undefined}
          >
            {item.label}
          </Text>
        </VStack>
      ))}
    </div>
  );
};

export const CreateKeySlideOver: React.FC<Props> = ({
  open,
  apps,
  saving,
  onOpenChange,
  onSave,
}) => {
  const formId = React.useId();
  const targetInputId = React.useId();
  const [state, setState] = React.useState<KeyEditorState>(newKeyEditorState);
  const [stage, setStage] = React.useState<EditorStage>(`target`);
  const [hasReachedReview, setHasReachedReview] = React.useState(false);
  const [showExpiration, setShowExpiration] = React.useState(false);
  const [showNote, setShowNote] = React.useState(false);

  React.useEffect(() => {
    if (!open) {
      return;
    }
    setState(newKeyEditorState());
    setStage(`target`);
    setHasReachedReview(false);
    setShowExpiration(false);
    setShowNote(false);
  }, [open]);

  const key = keyFromEditorState(state);
  const targetKey = keyFromEditorState({ ...state, scopeType: `webBrowsers` });
  const error = keyEditorError(state);
  const warning = broadAccessWarning(state);
  const normalizedAppBundleId = state.appBundleId
    .trim()
    .replace(/^\./, ``)
    .replace(/^[A-Z0-9]{10}\./, ``);
  const previewAppName =
    state.scopeType !== `singleApp`
      ? undefined
      : state.appIdentificationType === `identifiedAppSlug`
        ? apps.find((app) => app.slug === state.appSlug)?.name
        : apps.find((app) => app.bundleId === normalizedAppBundleId)?.name;
  const previewRecord = key
    ? {
        key,
        comment: state.comment.trim() || undefined,
        expiration: state.expiration?.toISOString(),
        appName: previewAppName,
      }
    : null;

  const changeTargetType = (targetType: KeyTargetType): void => {
    setState((current) => changeKeyEditorTargetType(current, targetType));
  };

  const changeAddress = (address: string): void => {
    setState((current) => changeKeyEditorAddress(current, address));
  };

  const changeMatching = (domainMatch: KeyEditorState[`domainMatch`]): void => {
    setState((current) => changeKeyEditorDomainMatch(current, domainMatch));
  };

  const changeScope = (scopeType: KeyScopeType): void => {
    setState((current) => ({ ...current, scopeType }));
  };

  const changeAppIdentificationType = (
    appIdentificationType: AppIdentificationType,
  ): void => {
    setState((current) => ({ ...current, appIdentificationType }));
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();

    if (stage === `target`) {
      if (!targetKey) {
        return;
      }
      setStage(hasReachedReview ? `review` : `scope`);
      return;
    }

    if (stage === `scope`) {
      if (!key) {
        return;
      }
      setHasReachedReview(true);
      setStage(`review`);
      return;
    }

    if (!key || saving) {
      return;
    }

    const comment = state.comment.trim();
    void onSave({
      key,
      comment: comment || undefined,
      expiration: state.expiration,
    }).then(
      () => onOpenChange(false),
      () => undefined,
    );
  };

  const handleFormKeyDown = (event: React.KeyboardEvent<HTMLFormElement>): void => {
    if (
      stage === `scope` &&
      event.key === `Enter` &&
      event.target instanceof HTMLInputElement &&
      event.target.type === `radio`
    ) {
      event.preventDefault();
      event.currentTarget.requestSubmit();
    }
  };

  const returnFromTarget = (): void => {
    if (hasReachedReview) {
      setStage(`review`);
    } else {
      onOpenChange(false);
    }
  };

  const returnFromScope = (): void => {
    setStage(`target`);
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={onOpenChange}
      ariaLabel="Add key"
      heading="Add a key"
      subheading="Set what to allow and where it should work."
      size="large"
      dismissible={!saving}
    >
      <VStack className="h-full">
        <SlideOver.Body className="px-3 @lg/slide:px-6">
          <form id={formId} onSubmit={handleSubmit} onKeyDown={handleFormKeyDown}>
            <VStack gap={5}>
              <FlowProgress stage={stage} />

              {stage === `target` && (
                <KeyTargetEditor
                  state={state}
                  inputId={targetInputId}
                  error={error}
                  warning={warning}
                  disabled={saving}
                  changeTargetType={changeTargetType}
                  changeAddress={changeAddress}
                  changeMatching={changeMatching}
                />
              )}

              {stage === `scope` && (
                <KeyScopeEditor
                  state={state}
                  apps={apps}
                  disabled={saving}
                  changeScope={changeScope}
                  changeAppIdentificationType={changeAppIdentificationType}
                  changeAppSlug={(appSlug) =>
                    setState((current) => ({ ...current, appSlug }))
                  }
                  changeAppBundleId={(appBundleId) =>
                    setState((current) => ({ ...current, appBundleId }))
                  }
                />
              )}

              {stage === `review` && (
                <VStack gap={4}>
                  <VStack gap={1}>
                    <Text as="h2" variant="heading">
                      Ready to add this key?
                    </Text>
                    <Text variant="bodySubtle" className="leading-6">
                      Check the key below before adding it.
                    </Text>
                  </VStack>

                  {previewRecord && (
                    <Card padding={0} className="overflow-hidden">
                      <KeyDisplay record={previewRecord} alwaysShowLabels />
                    </Card>
                  )}

                  {warning && <Banner variant="warning">{warning}</Banner>}

                  <VStack gap={4}>
                    <VStack gap={0.5}>
                      <Text as="h3" variant="bodyLargeStrong">
                        Anything else?
                      </Text>
                      <Text variant="captionSubtle" className="leading-5">
                        Expiration and notes are optional. Skip them unless they help you
                        manage this key.
                      </Text>
                    </VStack>

                    {(!showExpiration || !showNote) && (
                      <HStack wrap gap={2}>
                        {!showExpiration && (
                          <Button
                            type="button"
                            variant="default"
                            size="small"
                            icon={ClockIcon}
                            onClick={() => setShowExpiration(true)}
                          >
                            Add expiration
                          </Button>
                        )}
                        {!showNote && (
                          <Button
                            type="button"
                            variant="default"
                            size="small"
                            icon={FileTextIcon}
                            onClick={() => setShowNote(true)}
                          >
                            Add note
                          </Button>
                        )}
                      </HStack>
                    )}

                    {showExpiration && (
                      <DateTimePicker
                        label="Expiration"
                        date={state.expiration}
                        setDate={(expiration) =>
                          setState((current) => ({ ...current, expiration }))
                        }
                        notRequired
                        allowPast={false}
                      />
                    )}

                    {showNote && (
                      <Textarea
                        label="Note"
                        value={state.comment}
                        setValue={(comment) =>
                          setState((current) => ({ ...current, comment }))
                        }
                        placeholder="Why this key is needed"
                        rows={3}
                      />
                    )}
                  </VStack>
                </VStack>
              )}
            </VStack>
          </form>
        </SlideOver.Body>

        <SlideOver.Footer>
          {stage === `target` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={hasReachedReview ? ArrowLeftIcon : undefined}
                onClick={returnFromTarget}
                disabled={saving}
              >
                {hasReachedReview ? `Back to review` : `Cancel`}
              </Button>
              <Spacer />
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={ArrowRightIcon}
                iconPosition="right"
                disabled={!targetKey || saving}
              >
                {hasReachedReview ? `Review changes` : `Continue`}
              </Button>
            </>
          )}

          {stage === `scope` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={ArrowLeftIcon}
                onClick={returnFromScope}
                disabled={saving}
              >
                Back
              </Button>
              <Spacer />
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={ArrowRightIcon}
                iconPosition="right"
                disabled={!key || saving}
              >
                {hasReachedReview ? `Review changes` : `Review key`}
              </Button>
            </>
          )}

          {stage === `review` && (
            <>
              <Button
                type="button"
                variant="ghost"
                icon={ArrowLeftIcon}
                onClick={() => setStage(`scope`)}
                disabled={saving}
              >
                Back
              </Button>
              <Spacer />
              <Button
                type="button"
                variant="ghost"
                onClick={() => onOpenChange(false)}
                disabled={saving}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                form={formId}
                variant="primary"
                icon={KeyRoundIcon}
                disabled={!key || saving}
                loading={saving}
              >
                Add key
              </Button>
            </>
          )}
        </SlideOver.Footer>
      </VStack>
    </SlideOver>
  );
};

export default CreateKeySlideOver;
