import { Button, Input, Text, VStack } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React from 'react';
import RotatingTestimonials, {
  type Testimonial,
} from '#/components/unauthed/RotatingTestimonials';
import UnauthedForm from '#/components/unauthed/UnauthedForm';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';

interface Props {
  email: string;
  setEmail: (email: string) => void;
  password: string;
  setPassword: (password: string) => void;
  testimonials: Testimonial[];
  onSubmit: (event: React.FormEvent) => void;
}

const SignupPage: React.FC<Props> = ({
  email,
  setEmail,
  password,
  setPassword,
  testimonials,
  onSubmit,
}) => (
  <UnauthedPageLayout
    form={
      <UnauthedForm
        onSubmit={onSubmit}
        inputs={[
          <Input
            key="email"
            type="email"
            value={email}
            setValue={setEmail}
            label="Email"
            placeholder="john@doe.com"
          />,
          <Input
            key="password"
            type="password"
            value={password}
            setValue={setPassword}
            label="Password"
            placeholder="••••••••••"
          />,
        ]}
        buttons={[
          <Button
            key="signup"
            type="submit"
            variant="primary"
            icon={ArrowRightIcon}
            iconPosition="right"
          >
            Signup
          </Button>,
        ]}
        heading="Create an Account"
        subheading="Make an account to start protecting your children."
        disclaimer={
          <>
            By signing up, you agree to our{` `}
            <a
              href="https://gertrude.app/legal/terms"
              target="_blank"
              rel="noreferrer"
              className="underline decoration-dotted underline-offset-2"
            >
              terms of service
            </a>
            .
          </>
        }
        bottomLink={{
          text: `Login instead`,
          href: `/login`,
        }}
        bottomLinkExplanation="Already have an account?"
      />
    }
    rightDisplay={
      <VStack align="center" className="h-full overflow-hidden pt-20 relative">
        <img src="/logo-wordmark.svg" alt="Gertrude" className="w-36 relative" />
        <Text as="h2" variant="display" className="mt-8 relative">
          Here's what parents are saying.
        </Text>
        <Text as="h3" variant="subheading" className="mt-1 relative mb-4">
          Just in case you'd be inclined to doubt us.
        </Text>
        <RotatingTestimonials testimonials={testimonials} />
      </VStack>
    }
  />
);

export default SignupPage;
