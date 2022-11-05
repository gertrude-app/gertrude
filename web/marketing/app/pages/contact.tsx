import { useState } from 'react';
import cx from 'classnames';
import type { NextPage } from 'next';
import { TextInput, Logo, Button, LoadingSpinner } from '@shared/components';
import { Chrome, ContactStatusMessage } from '@marketing/components';

const Contact: NextPage = () => {
  const [state, setState] = useState<'idle' | 'ongoing' | 'failed' | 'succeeded'>(`idle`);
  const [name, setName] = useState(``);
  const [emailAddress, setEmailAddress] = useState(``);
  const [subject, setSubject] = useState(``);
  const [message, setMessage] = useState(``);

  return (
    <Chrome>
      <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 flex-grow flex flex-col justify-center items-center p-6 py-6">
        <div className="bg-white p-6 sm:p-8 rounded-xl shadow-xl flex flex-col sm:flex-row overflow-hidden relative w-full sm:w-auto sm:space-x-6">
          <div className="sm:w-56 md:w-72 mb-6 sm:mb-0 space-y-2">
            <h1 className="text-2xl font-inter text-gray-900">Contact us</h1>
            {state === `ongoing` && (
              <div className="hidden sm:block sm:pt-8">
                <LoadingSpinner />
              </div>
            )}
            {state === `failed` && (
              <ContactStatusMessage
                type="error"
                heading="Uh oh!"
                message="Something went wrong. Please refresh the page and try again."
              />
            )}
            {state === `succeeded` && (
              <ContactStatusMessage
                type="success"
                heading="Got it!"
                message="Thanks for your message. We'll usually respond within one business day or sooner."
              />
            )}
            <Logo
              iconOnly
              size={300}
              className="absolute -left-10 -bottom-24 opacity-20"
            />
          </div>
          <form
            className={cx(
              `sm:w-72 md:w-96 space-y-5 flex flex-col`,
              state !== `idle` && `hidden sm:flex`,
            )}
            name="contact"
            data-netlify="true"
            method="POST"
            onSubmit={(event) => {
              event.preventDefault();
              const params = new URLSearchParams();
              params.append(`form-name`, `contact`);
              params.append(`name`, name);
              params.append(`email_address`, emailAddress);
              params.append(`subject`, subject);
              params.append(`message`, message);
              setState(`ongoing`);
              try {
                fetch(`/`, {
                  method: `POST`,
                  headers: { 'Content-Type': `application/x-www-form-urlencoded` },
                  body: params.toString(),
                })
                  .then(() => setState(`succeeded`))
                  .catch(() => setState(`failed`));
              } catch {
                setState(`failed`);
              }
            }}
          >
            <TextInput
              type="text"
              label="Name"
              name="name"
              autoFocus
              required
              placeholder="Your name"
              value={name}
              setValue={setName}
            />
            <TextInput
              type="email"
              name="email_address"
              label="Email address"
              required
              placeholder="you@example.com"
              value={emailAddress}
              setValue={setEmailAddress}
            />
            <TextInput
              type="text"
              name="subject"
              label="Subject"
              required
              value={subject}
              setValue={setSubject}
            />
            <TextInput
              type="textarea"
              label="Message"
              name="message"
              required
              rows={4}
              value={message}
              setValue={setMessage}
            />
            <Button
              className="self-end relative z-10"
              type="submit"
              color="primary-violet"
              disabled={state === `ongoing` || state === `succeeded`}
            >
              <i className="fa-solid fa-arrow-right mr-3" />
              Submit
            </Button>
          </form>
        </div>
      </section>
    </Chrome>
  );
};

export default Contact;
