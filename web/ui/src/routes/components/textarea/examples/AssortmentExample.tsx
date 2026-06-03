import React, { useState } from 'react';
import Textarea from '#/components/ui/Textarea';

const AssortmentExample: React.FC = () => {
  const [note, setNote] = useState(
    `Sally can use research sites until the science project is done.`,
  );
  const [reason, setReason] = useState(``);
  const [supportMessage, setSupportMessage] = useState(``);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="grid w-full max-w-4xl gap-5 sm:grid-cols-2">
        <Textarea label="Parent note" value={note} setValue={setNote} rows={4} />
        <Textarea
          label="Unlock reason"
          value={reason}
          setValue={setReason}
          placeholder="Why should this site be allowed?"
          helperText="Visible to parents on this account."
          rows={4}
        />
        <Textarea
          label="Missing explanation"
          value=""
          setValue={() => undefined}
          error="Add a reason before approving this request."
          rows={3}
          resize="none"
        />
        <Textarea
          label="Support message"
          value={supportMessage}
          setValue={setSupportMessage}
          placeholder="Tell us what happened..."
          rows={3}
          resize="vertical"
        />
        <Textarea
          label="Managed note"
          value="This setting is managed by the school profile."
          setValue={() => undefined}
          disabled
          rows={3}
        />
      </div>
    </div>
  );
};

export default AssortmentExample;
