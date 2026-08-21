import {
  Button,
  DropdownMenu,
  DropdownMenuCheckboxItem,
  HStack,
  Text,
} from '@gertrude/ui';
import { ChevronDownIcon } from 'lucide-react';
import React from 'react';
import type { AssignablePerson } from '#/components/types';

interface Props {
  people: AssignablePerson[];
  assignedPersonIds: string[];
  onAssignmentChange: (personId: string, assigned: boolean) => Promise<void>;
}

const assignmentButtonLabel = (
  people: AssignablePerson[],
  assignedPersonIds: string[],
): string => {
  if (people.length === 0) {
    return `No people to assign`;
  }

  if (assignedPersonIds.length === 0) {
    return `Not assigned`;
  }

  if (assignedPersonIds.length === 1) {
    const person = people.find(({ id }) => id === assignedPersonIds[0]);
    return person?.name ?? `1 person`;
  }

  return `${assignedPersonIds.length} people`;
};

const KeychainAssignmentMenu: React.FC<Props> = ({
  people,
  assignedPersonIds,
  onAssignmentChange,
}) => {
  const [pendingPersonIds, setPendingPersonIds] = React.useState<Set<string>>(
    () => new Set(),
  );
  const assignedIds = new Set(assignedPersonIds);
  const buttonLabel = assignmentButtonLabel(people, assignedPersonIds);
  const hasAssignments = assignedPersonIds.length > 0;

  const setAssignment = async (personId: string, assigned: boolean): Promise<void> => {
    if (pendingPersonIds.has(personId)) {
      return;
    }

    setPendingPersonIds((current) => new Set(current).add(personId));
    try {
      await onAssignmentChange(personId, assigned);
    } catch {
      return;
    } finally {
      setPendingPersonIds((current) => {
        const next = new Set(current);
        next.delete(personId);
        return next;
      });
    }
  };

  return (
    <HStack gap={1} align="center">
      {hasAssignments && <Text variant="label">Assigned to</Text>}
      <DropdownMenu
        searchable={people.length > 7}
        disabled={people.length === 0}
        contentClassName="w-64"
        trigger={
          <Button
            type="button"
            variant="default"
            size="small"
            onClick={() => {}}
            disabled={people.length === 0}
            icon={ChevronDownIcon}
            iconPosition="right"
            className="max-w-52"
            ariaLabel={hasAssignments ? `Assigned to ${buttonLabel}` : buttonLabel}
          >
            {buttonLabel}
          </Button>
        }
      >
        {people.map((person) => (
          <DropdownMenuCheckboxItem
            key={person.id}
            title={person.name}
            checked={assignedIds.has(person.id)}
            disabled={pendingPersonIds.has(person.id)}
            onCheckedChange={(assigned) => {
              void setAssignment(person.id, assigned);
            }}
          />
        ))}
      </DropdownMenu>
    </HStack>
  );
};

export default KeychainAssignmentMenu;
