import { useState } from 'react';
import type { NextPage } from 'next';
import Chrome from 'components/Chrome';
import TextInput from '@shared/TextInput';
import Logo from '@shared/Logo';
import Button from '@shared/Button';

const Contact: NextPage = () => {
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
            {/* ContactStatusMessages go here, they shouldn't need any custom classNames */}
            <Logo
              iconOnly
              size={300}
              className="absolute -left-10 -bottom-24 opacity-20"
            />
          </div>
          <div>
            <form className="sm:w-72 md:w-96 space-y-5 flex flex-col">
              <TextInput
                type="text"
                label="Name"
                placeholder="George Washington"
                value={name}
                setValue={setName}
              />
              <TextInput
                type="email"
                label="Email address"
                placeholder="me@example.com"
                value={emailAddress}
                setValue={setEmailAddress}
              />
              <TextInput
                type="text"
                label="Subject"
                placeholder="Interesting subject"
                value={subject}
                setValue={setSubject}
              />
              <TextInput
                type="textarea"
                label="Message"
                rows={4}
                placeholder="Compelling message"
                value={message}
                setValue={setMessage}
              />
              <Button
                type="button"
                color="primary-violet"
                onClick={() => {}}
                className="self-end"
              >
                <i className="fa-solid fa-arrow-right mr-3" />
                Submit
              </Button>
            </form>
          </div>
        </div>
      </section>
    </Chrome>
  );
};

export default Contact;
