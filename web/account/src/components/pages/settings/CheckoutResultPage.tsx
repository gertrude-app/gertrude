import { Button, LoadingDots, Text, VStack } from '@gertrude/ui';
import {
  CheckCircleIcon,
  CircleAlertIcon,
  ExternalLinkIcon,
  XCircleIcon,
} from 'lucide-react';
import React from 'react';
import CardContainer from '#/components/layout/CardContainer';

type Props =
  | { status: `loading` }
  | { status: `success` }
  | { status: `error`; message: string }
  | { status: `canceled` };

const CheckoutResultPage: React.FC<Props> = (props) => {
  if (props.status === `loading`) {
    return (
      <CardContainer className="mt-4">
        <VStack align="center" gap={3} className="py-12 text-center">
          <LoadingDots />
          <Text as="h2" variant="heading">
            Confirming your subscription…
          </Text>
          <Text as="p" variant="bodyMuted">
            Keep this page open while Gertrude checks the payment with Stripe.
          </Text>
        </VStack>
      </CardContainer>
    );
  }

  const content =
    props.status === `success`
      ? {
          icon: CheckCircleIcon,
          iconClassName: `text-green-600`,
          title: `Payment setup complete`,
          description: `Your Gertrude subscription is ready. You can manage or cancel it from Billing at any time.`,
        }
      : props.status === `canceled`
        ? {
            icon: XCircleIcon,
            iconClassName: `text-stone-500`,
            title: `Payment setup canceled`,
            description: `No plan changes were made. You can return to Billing whenever you're ready.`,
          }
        : {
            icon: CircleAlertIcon,
            iconClassName: `text-red-600`,
            title: `Couldn't confirm the subscription`,
            description: props.message,
          };
  const Icon = content.icon;

  return (
    <CardContainer className="mt-4">
      <VStack align="center" gap={3} className="py-10 text-center">
        <Icon className={`h-12 w-12 ${content.iconClassName}`} />
        <Text as="h2" variant="title">
          {content.title}
        </Text>
        <Text as="p" variant="proseSubtle" className="max-w-lg">
          {content.description}
        </Text>
        <div className="mt-3 flex flex-col gap-2 xs:flex-row">
          <Button type="link" href="/settings/billing" variant="primary">
            Back to Billing
          </Button>
          {props.status !== `success` && (
            <Button
              type="link"
              href="https://gertrude.app/contact"
              variant="default"
              icon={ExternalLinkIcon}
            >
              Contact support
            </Button>
          )}
        </div>
      </VStack>
    </CardContainer>
  );
};

export default CheckoutResultPage;
