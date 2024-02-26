import React from 'react';
import cx from 'classnames';
import { SendIcon } from 'lucide-react';
import type { NextPage } from 'next';
import { axiforma } from '../../../lib/fonts';
import FancyLink from '../../../components/FancyLink';

const ContactPage: NextPage = () => (
  <div className="flex justify-center items-center px-0 xs:px-8 py-8 sm:px-12 sm:py-12 md:px-20 md:py-20">
    <div className="bg-white p-8 xs:p-12 sm:p-16 lg:p-20 rounded-[40px] flex flex-col">
      <h1 className={cx(`text-4xl font-semibold self-center lg:self-start`, axiforma)}>
        Contact us
      </h1>
      <p className="text-xl mt-3 text-slate-500 max-w-2xl self-center lg:self-start text-center lg:text-left">
        Lorem ipsum dolor sit amet, qui minim labore adipisicing minim sint cillum sint
        consectetur cupidatat.
      </p>
      <form className="flex flex-col">
        <div className="flex flex-col lg:flex-row gap-8 mt-8">
          <div className=" flex flex-col gap-8">
            <TextInput name="name" label="Name" type="text" />
            <TextInput name="email" label="Email" type="email" />
            <TextInput name="subject" label="Subject" type="text" />
          </div>
          <TextInput name="message" label="Message" type="text" textarea />
        </div>
        <FancyLink href="#" className="self-end mt-8" Icon={SendIcon}>
          Submit
        </FancyLink>
      </form>
    </div>
  </div>
);

export default ContactPage;

interface TextInputProps {
  name: string;
  label: string;
  type: 'text' | 'email';
  textarea?: boolean;
}

const TextInput: React.FC<TextInputProps> = ({ name, label, type, textarea }) => {
  const classes = cx(
    `rounded-2xl bg-slate-100 py-4 px-4 text-xl w-full lg:w-96 xl:w-112 outline-none focus:ring-0 focus:outline-2 focus:outline-violet-400 border-none`,
  );
  return (
    <div className="flex flex-col">
      <label
        htmlFor={name}
        className={cx(`font-medium text-lg text-slate-400`, axiforma)}
      >
        {label}
      </label>
      {textarea ? (
        <textarea name={name} id={name} className={cx(classes, `h-full`)} />
      ) : (
        <input name={name} id={name} type={type} className={classes} />
      )}
    </div>
  );
};
