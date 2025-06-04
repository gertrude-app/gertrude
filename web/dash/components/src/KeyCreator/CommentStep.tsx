import { EditKey } from '@dash/keys';
import { TextInput } from '@shared/components';
import React from 'react';
import GradientIcon from '../GradientIcon';
import UserInputText from '../UserInputText';
import KeyCreationStep from './KeyCreationStep';

interface Props {
  mode: `edit` | `create`;
  activeStep: EditKey.Step;
  comment?: string;
  update(event: EditKey.Event): unknown;
}

const CommentStep: React.FC<Props> = ({ mode, update, activeStep, comment }) => (
  <KeyCreationStep
    mode={mode}
    update={update}
    lookaheadTitle="Add an optional comment"
    activeTitle="Add an optional comment:"
    title={
      <h2 className="font-medium text-slate-900 text-lg flex items-center space-x-2">
        <GradientIcon icon="comment" className="mr-2" size="small" />
        <span>
          {comment ? (
            <>
              With the comment <UserInputText>&ldquo;{comment}&rdquo;</UserInputText>
            </>
          ) : (
            `No comment`
          )}
        </span>
      </h2>
    }
    activeStep={activeStep}
    ownStep={EditKey.Step.Comment}
  >
    <TextInput
      type="textarea"
      value={comment ?? ``}
      setValue={(newValue) => update({ type: `setComment`, to: newValue })}
      placeholder="Optional note to yourself about this key"
    />
  </KeyCreationStep>
);

export default CommentStep;
