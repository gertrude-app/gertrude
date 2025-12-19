'use client';

import cx from 'classnames';
import { CheckIcon, Loader2Icon, SendIcon, XIcon } from 'lucide-react';
import React, { useState } from 'react';
import Turnstile from 'react-turnstile';
import FancyLink from './FancyLink';
import * as env from '@/lib/env';

const ContactForm: React.FC = () => {
  const [state, setState] = useState<`idle` | `ongoing` | `failed` | `succeeded`>(`idle`);
  const [name, setName] = useState(``);
  const [emailAddress, setEmailAddress] = useState(``);
  const [app, setApp] = useState(``);
  const [subject, setSubject] = useState(``);
  const [message, setMessage] = useState(``);
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null);
  const { formsEndpoint, turnstileSitekey } = env.getPublicVars();

  return (
    <form
      className="flex flex-col relative"
      name="contact"
      method="POST"
      onSubmit={(event) => {
        event.preventDefault();
        if (!turnstileToken) {
          setState(`failed`);
          return;
        }
        const params = new URLSearchParams();
        params.append(`form`, `contact`);
        params.append(`name`, name);
        params.append(`email`, emailAddress);
        params.append(`app`, app);
        params.append(`subject`, subject);
        params.append(`message`, message);
        params.append(`turnstileToken`, turnstileToken);
        setState(`ongoing`);
        try {
          fetch(formsEndpoint, {
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
      <div className="flex flex-col lg:flex-row gap-8 mt-8">
        <div className="flex-1 min-w-0 flex flex-col gap-8">
          <TextInput
            name="name"
            label="Name"
            type="text"
            value={name}
            setValue={setName}
            required
            autoFocus
          />
          <TextInput
            name="email"
            label="Email"
            type="email"
            value={emailAddress}
            setValue={setEmailAddress}
            required
          />
          <SelectInput
            name="app"
            label="Which Gertrude product?"
            value={app}
            setValue={setApp}
            options={[
              { value: ``, label: `Please select...` },
              { value: `mac`, label: `Gertrude for Mac` },
              { value: `ios`, label: `Gertrude Blocker for iPhone/iPad` },
              { value: `podcasts`, label: `Gertrude AM (Podcasts)` },
              { value: `unsure`, label: `I’m not sure / something else` },
            ]}
            required
          />
          <TextInput
            name="subject"
            label="Subject"
            type="text"
            value={subject}
            setValue={setSubject}
            required
          />
        </div>
        <div className="flex-1 min-w-0">
          <TextInput
            textarea
            name="message"
            label="Message"
            type="text"
            value={message}
            setValue={setMessage}
            required
          />
        </div>
      </div>
      <Turnstile
        sitekey={turnstileSitekey}
        refreshExpired="auto"
        onVerify={setTurnstileToken}
      />
      {state === `idle` && (
        <FancyLink
          type="submit"
          className="self-end mt-8"
          Icon={SendIcon}
          color="primary"
          size="lg"
        >
          Submit
        </FancyLink>
      )}
      {state === `ongoing` && (
        <Loader2Icon className="self-end mt-8 mr-8 animate-spin text-slate-700" />
      )}
      {state === `succeeded` && (
        <div className="bg-green-100 mt-8 rounded-3xl p-8 text-xl text-green-700 font-medium flex justify-between items-center gap-4">
          <span>Message sent!</span>
          <CheckIcon className="shrink-0" />
        </div>
      )}
      {state === `failed` && (
        <div className="bg-red-100 mt-8 rounded-3xl p-8 text-xl text-red-700 font-medium flex justify-between items-center gap-4">
          <span>Hmm, that didn't work. Please try again.</span>
          <XIcon className="shrink-0" />
        </div>
      )}
    </form>
  );
};

export default ContactForm;

interface TextInputProps {
  name: string;
  label: string;
  type: `text` | `email`;
  value: string;
  setValue: (value: string) => void;
  textarea?: boolean;
  required?: boolean;
  autoFocus?: boolean;
}

const TextInput: React.FC<TextInputProps> = ({
  name,
  label,
  type,
  textarea,
  value,
  setValue,
  required,
  autoFocus,
}) => {
  const classes = cx(
    `rounded-2xl bg-slate-100 py-4 px-4 text-xl w-full outline-none focus:ring-0 focus:outline-2 focus:outline-violet-400 border-none`,
  );
  return (
    <div className="flex flex-col h-full gap-1">
      <label htmlFor={name} className="font-medium text-lg text-slate-400">
        {label}
      </label>
      {textarea ? (
        <textarea
          value={value}
          onChange={(e) => setValue(e.target.value)}
          name={name}
          id={name}
          className={cx(classes, `h-full`)}
          required={required}
          autoFocus={autoFocus}
        />
      ) : (
        <input
          value={value}
          onChange={(e) => setValue(e.target.value)}
          name={name}
          id={name}
          type={type}
          className={classes}
          required={required}
          autoFocus={autoFocus}
        />
      )}
    </div>
  );
};

interface SelectInputProps {
  name: string;
  label: string;
  value: string;
  setValue: (value: string) => void;
  options: Array<{ value: string; label: string }>;
  required?: boolean;
}

const SelectInput: React.FC<SelectInputProps> = ({
  name,
  label,
  value,
  setValue,
  options,
  required,
}) => (
  <div className="flex flex-col gap-1">
    <label htmlFor={name} className="font-medium text-lg text-slate-400">
      {label}
    </label>
    <select
      value={value}
      onChange={(e) => setValue(e.target.value)}
      name={name}
      id={name}
      className="rounded-2xl bg-slate-100 py-4 px-4 text-xl w-full outline-none focus:ring-0 focus:outline-2 focus:outline-violet-400 border-none"
      required={required}
    >
      {options.map((option) => (
        <option key={option.value} value={option.value}>
          {option.label}
        </option>
      ))}
    </select>
  </div>
);
