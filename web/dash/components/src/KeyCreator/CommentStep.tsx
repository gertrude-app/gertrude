import React from 'react';
import { TextInput } from '@shared/components';
import { EditKey } from '@dash/keys';
import GradientIcon from '../GradientIcon';
import UserInputText from '../UserInputText';
import KeyCreationStep from './KeyCreationStep';

interface Props {
  mode: 'edit' | 'create';
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
      <h2 className="font-medium text-slate-900 text-lg">
        <GradientIcon icon="comment" className="mr-2" size="small" />
        {comment ? (
          <>
            With the comment <UserInputText>&ldquo;{comment}&rdquo;</UserInputText>
          </>
        ) : (
          `No comment`
        )}
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
