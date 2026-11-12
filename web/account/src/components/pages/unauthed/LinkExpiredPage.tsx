import { Button } from '@gertrude/ui';
import { ClockIcon } from 'lucide-react';
import React from 'react';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

const LinkExpiredPage: React.FC = () => (
  <UnauthedPageLayout
    form={
      <UnauthedForm
        icon={ClockIcon}
        heading="Link expired"
        subheading="This link has expired. Gertrude SMS short links are only valid for 7 days."
        inputs={[]}
        buttons={[
          <Button key="account" type="link" href="/" variant="primary">
            Go to your account
          </Button>,
        ]}
      />
    }
  />
);

export default LinkExpiredPage;
