import { Button, SelectMenu, TextInput } from '@shared/components';
import React, { useState } from 'react';

export type ChildSelection =
  | { type: `existing`; id: UUID }
  | { type: `new`; name: string };

type Props = {
  children: Array<{ id: UUID; name: string }>;
  deviceType: string;
  onSubmit: (selection: ChildSelection) => void;
  onCancel: () => void;
  isSubmitting: boolean;
  error?: string;
};

const NEW_CHILD_VALUE = `__new__`;

const ChildAssignmentPicker: React.FC<Props> = ({
  children,
  deviceType,
  onSubmit,
  onCancel,
  isSubmitting,
  error,
}) => {
  const hasChildren = children.length > 0;
  const [selectedValue, setSelectedValue] = useState<string>(
    hasChildren ? (children[0]?.id ?? NEW_CHILD_VALUE) : NEW_CHILD_VALUE,
  );
  const [newChildName, setNewChildName] = useState(``);
  const isNewChild = selectedValue === NEW_CHILD_VALUE;
  const canSubmit = isNewChild ? newChildName.trim().length > 0 : !!selectedValue;

  const handleSubmit = (e: React.FormEvent): void => {
    e.preventDefault();
    if (!canSubmit || isSubmitting) return;

    if (isNewChild) {
      onSubmit({ type: `new`, name: newChildName.trim() });
    } else {
      onSubmit({ type: `existing`, id: selectedValue as UUID });
    }
  };

  const options = [
    ...children.map((child) => ({ value: child.id, display: child.name })),
    { value: NEW_CHILD_VALUE, display: `Add someone new...` },
  ];

  if (!hasChildren) {
    return (
      <form onSubmit={handleSubmit} className="w-full">
        <div className="mb-6">
          <h3 className="text-slate-700 font-medium mb-3">Name of {deviceType} owner:</h3>
          <TextInput
            type="text"
            value={newChildName}
            setValue={setNewChildName}
            testId="child-name-input"
            autoFocus
            disabled={isSubmitting}
          />
        </div>
        {error && <ErrorMessage message={error} />}
        <div className="flex justify-end gap-3 mt-6">
          <Button
            type="button"
            color="secondary"
            onClick={onCancel}
            disabled={isSubmitting}
          >
            Cancel
          </Button>
          <Button
            type="submit"
            color="primary"
            disabled={!canSubmit || isSubmitting}
            className="min-w-[100px]"
          >
            {isSubmitting ? `Adding...` : `Add Device`}
          </Button>
        </div>
      </form>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="w-full">
      <div className="mb-6">
        <h3 className="text-slate-700 font-medium mb-3">
          Who does this device belong to?
        </h3>
        <SelectMenu
          options={options}
          selectedOption={selectedValue}
          setSelected={setSelectedValue}
          disabled={isSubmitting}
        />
        {isNewChild && (
          <div className="mt-3">
            <TextInput
              type="text"
              value={newChildName}
              setValue={setNewChildName}
              placeholder="Enter name"
              autoFocus
              disabled={isSubmitting}
            />
          </div>
        )}
      </div>
      {error && <ErrorMessage message={error} />}
      <div className="flex justify-end gap-3 mt-6">
        <Button
          type="button"
          color="secondary"
          onClick={onCancel}
          disabled={isSubmitting}
        >
          Cancel
        </Button>
        <Button
          type="submit"
          color="primary"
          disabled={!canSubmit || isSubmitting}
          className="min-w-[100px]"
        >
          {isSubmitting ? `Adding...` : `Continue`}
        </Button>
      </div>
    </form>
  );
};

export default ChildAssignmentPicker;

const ErrorMessage: React.FC<{ message: string }> = ({ message }) => (
  <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
    <p className="text-red-700 text-sm">{message}</p>
  </div>
);
