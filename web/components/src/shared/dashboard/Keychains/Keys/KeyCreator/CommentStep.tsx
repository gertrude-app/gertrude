import React from 'react';
import TextInput from '../../../TextInput';
import KeyCreationStep from '../KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'edit' | 'create';
  currentStepIndex: number;
  comment?: string;
}

const CommentStep: React.FC<Props> = ({ mode, currentStepIndex, comment }) => (
  <KeyCreationStep
    mode={mode}
    setCurrentStep={() => {}}
    lookaheadTitle="Add an optional comment"
    activeTitle="Add an optional comment:"
    title={
      <h2 className="font-medium text-gray-900 text-lg">
        <GradientIcon icon="comment" className="mr-2" />
        {comment ? (
          <>
            With the comment <UserInputText>&ldquo;{comment}&rdquo;</UserInputText>
          </>
        ) : (
          `No comment`
        )}
      </h2>
    }
    currentStep={currentStepIndex}
    index={9}
    isLast
  >
    <TextInput
      type="textarea"
      value=""
      setValue={() => {}}
      placeholder="Optional note to yourself about this key"
    />
  </KeyCreationStep>
);

export default CommentStep;
