import React, { useState } from 'react';
import Button from '#/components/ui/Button';
import Input from '#/components/ui/Input';
import Select from '#/components/ui/Select';
import Toggle from '#/components/ui/Toggle';
import Form from '#/components/ui/form/Form';
import FormRow from '#/components/ui/form/FormRow';

const modeOptions = [`Homework first`, `Bedtime`, `Weekend`, `Custom`] as const;
const reviewOptions = [
  `Ask parent`,
  `Block until tomorrow`,
  `Allow school sites`,
] as const;

const SettingsExample: React.FC = () => {
  const [mode, setMode] = useState<(typeof modeOptions)[number]>(`Homework first`);
  const [site, setSite] = useState(`khanacademy.org`);
  const [limit, setLimit] = useState(`45`);
  const [review, setReview] = useState<(typeof reviewOptions)[number]>(`Ask parent`);
  const [requestsEnabled, setRequestsEnabled] = useState(true);
  const [notificationsEnabled, setNotificationsEnabled] = useState(false);

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="w-full max-w-2xl">
        <Form>
          <FormRow
            label="Rule mode"
            description="Start with a preset, then tune individual controls below."
          >
            <Select selected={mode} setSelected={setMode} possibleValues={modeOptions} />
          </FormRow>
          <FormRow
            label="Allowed site"
            description="Enter a host without https:// or a path."
          >
            <Input type="text" value={site} setValue={setSite} prefix="https://" />
          </FormRow>
          <FormRow label="Daily limit">
            <Input type="number" value={limit} setValue={setLimit} suffix="minutes" />
          </FormRow>
          <FormRow label="When the limit is reached">
            <Select
              selected={review}
              setSelected={setReview}
              possibleValues={reviewOptions}
            />
          </FormRow>
          <FormRow
            label="Unlock requests"
            description="Let children ask for access from the block page."
          >
            <Toggle checked={requestsEnabled} setChecked={setRequestsEnabled} />
          </FormRow>
          <FormRow
            label="Parent notifications"
            description="Send an alert when this rule blocks a new site."
          >
            <Toggle checked={notificationsEnabled} setChecked={setNotificationsEnabled} />
          </FormRow>
          <FormRow description="Actions can live in a final row without a label.">
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={() => undefined}>
                Cancel
              </Button>
              <Button type="button" variant="primary" onClick={() => undefined}>
                Save rule
              </Button>
            </div>
          </FormRow>
        </Form>
      </div>
    </div>
  );
};

export default SettingsExample;
