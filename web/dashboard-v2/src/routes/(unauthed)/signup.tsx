import { createFileRoute } from '@tanstack/react-router';
import { Button, Input } from '@gertrude/ui';
import { ArrowRightIcon } from 'lucide-react';
import React, { useState } from 'react';
import RotatingTestimonials from '#/components/unauthed/RotatingTestimonials';
import UnauthedPageLayout from '#/components/unauthed/UnauthedPageLayout';
import UnauthedForm from '#/components/unauthed/UnauthedForm';

const SignupPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <UnauthedPageLayout
      form={
        <UnauthedForm
          inputs={[
            <Input
              type="email"
              value={email}
              setValue={setEmail}
              label="Email"
              placeholder="john@doe.com"
            />,
            <Input
              type="password"
              value={password}
              setValue={setPassword}
              label="Password"
              placeholder="••••••••••"
            />,
          ]}
          buttons={[
            <Button
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
          bottomLink={{
            text: 'Login instead',
            href: '/login',
          }}
          bottomLinkExplanation="Already have an account?"
        />
      }
      rightDisplay={
        <div className="flex h-full flex-col items-center overflow-hidden pt-20 relative">
          <img src="/logo-wordmark.svg" className="w-36 relative" />
          <h2 className="text-3xl font-medium text-stone-900 mt-8 relative">
            Here's what parents are saying.
          </h2>
          <h3 className="text-lg text-stone-600 mt-1 relative mb-4">
            Just in case you'd be inclined to doubt us.
          </h3>
          <RotatingTestimonials />
        </div>
      }
    />
  );
};

export const Route = createFileRoute('/(unauthed)/signup')({
  component: SignupPage,
});
