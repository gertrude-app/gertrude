'use client';

import React, { useState } from 'react';
import cx from 'classnames';
import { CheckIcon, Loader2Icon, SendIcon, XIcon } from 'lucide-react';
import FancyLink from './FancyLink';

const ContactForm: React.FC = () => {
  const [state, setState] = useState<'idle' | 'ongoing' | 'failed' | 'succeeded'>(`idle`);
  const [name, setName] = useState(``);
  const [emailAddress, setEmailAddress] = useState(``);
  const [subject, setSubject] = useState(``);
  const [message, setMessage] = useState(``);

  return (
    <form
      className="flex flex-col relative"
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
      <div className="flex flex-col lg:flex-row gap-8 mt-8">
        <div className=" flex flex-col gap-8">
          <TextInput
            name="name"
            label="Name"
            type="text"
            value={name}
            setValue={setName}
            required
          />
          <TextInput
            name="email"
            label="Email"
            type="email"
            value={emailAddress}
            setValue={setEmailAddress}
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
      <div></div>
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
  type: 'text' | 'email';
  value: string;
  setValue: (value: string) => void;
  textarea?: boolean;
  required?: boolean;
}

const TextInput: React.FC<TextInputProps> = ({
  name,
  label,
  type,
  textarea,
  value,
  setValue,
  required,
}) => {
  const classes = cx(
    `rounded-2xl bg-slate-100 py-4 px-4 text-xl w-full lg:w-96 xl:w-112 outline-none focus:ring-0 focus:outline-2 focus:outline-violet-400 border-none`,
  );
  return (
    <div className="flex flex-col">
      <label htmlFor={name} className="font-axiforma font-medium text-lg text-slate-400">
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
        />
      )}
    </div>
  );
};
