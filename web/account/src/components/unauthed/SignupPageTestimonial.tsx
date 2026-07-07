import { Card, Text, VStack } from '@gertrude/ui';
import React from 'react';

interface Props {
  quote: string;
  name?: string;
}

const SignupPageTestimonial: React.FC<Props> = ({ quote, name }) => (
  <Card preset="big" padding={6} className="!bg-stone-50 shadow-stone-300/20">
    <VStack gap={4}>
      <Text as="p" variant="bodyLarge">
        {quote}
      </Text>
      {name && (
        <Text as="p" variant="captionMuted" className="self-end -mb-2">
          {name}
        </Text>
      )}
    </VStack>
  </Card>
);

export default SignupPageTestimonial;
