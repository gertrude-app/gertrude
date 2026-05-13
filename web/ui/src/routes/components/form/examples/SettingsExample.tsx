import Button from '#/components/ui/Button';
import Form from '#/components/ui/form/Form';
import FormRow from '#/components/ui/form/FormRow';
import Input from '#/components/ui/Input';
import Select from '#/components/ui/Select';
import React, { useState } from 'react';

const SettingsExample: React.FC = () => {
  const [mode, setMode] = useState('Homework first');
  const [site, setSite] = useState('khanacademy.org');
  const [limit, setLimit] = useState('45');
  const [review, setReview] = useState('Ask parent');

  return (
    <div className="grid h-full place-items-center p-8">
      <div className="w-full max-w-2xl">
        <Form>
          <FormRow
            label="Rule mode"
            description="Start with a preset, then tune individual controls below."
          >
            <Select
              selected={mode}
              setSelected={setMode}
              possibleValues={['Homework first', 'Bedtime', 'Weekend', 'Custom']}
            />
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
              possibleValues={[
                'Ask parent',
                'Block until tomorrow',
                'Allow school sites',
              ]}
            />
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
