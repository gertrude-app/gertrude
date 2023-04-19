import { Logo, TextInput } from '@shared/components';
import { Modal, SelectableListItem } from '@dash/components';
import type { StoryObj, Meta } from '@storybook/react';
import { props } from '../../story-helpers';

const meta = {
  title: 'Dashboard/Modal/Modal', // eslint-disable-line
  component: Modal,
  parameters: { layout: `fullscreen` },
} satisfies Meta<typeof Modal>;

type Story = StoryObj<typeof meta>;

export const Default: Story = props({
  type: `default`,
  title: `Just fyi...`,
  isOpen: true,
  primaryButton: () => {},
  secondaryButton: { action: () => {} },
  onDismiss: () => {},
  children: (
    <>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Dolorem aliquam autem eius,
      facere laudantium temporibus ea quasi.
    </>
  ),
  icon: `info`,
});

export const TinyError: Story = props({
  ...Default.args,
  title: `Error`,
  secondaryButton: undefined,
  children: `User not found`,
});

export const Loading: Story = props({
  ...Default.args,
  loading: true,
});

export const Destructive: Story = props({
  ...Default.args,
  type: `destructive`,
  title: `NOOOOOOOOO!!!`,
  icon: `exclamation-triangle`,
  primaryButton: { label: `Delete`, action: () => {} },
});

export const Container: Story = props({
  ...Default.args,
  type: `container`,
  title: `Cute little container`,
  icon: `list`,
  children: (
    <div className="flex flex-col space-y-3">
      {[
        `Here's a thing`,
        `Here's another thing`,
        `Here's yet another thing`,
        `Surprise: another thing`,
        `You won't believe this, but...`,
        `Get this: another thing`,
        `Thing thing thing thing`,
      ].map((thing) => (
        <div key={thing}>
          <h1 className="text-lg font-bold">{thing}</h1>
          <p>
            Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere
            laudantium unde eos quibusdam possimus id.
          </p>
        </div>
      ))}
    </div>
  ),
});

export const ContainerAlt: Story = props({
  ...Container.args,
  icon: `hamburger`,
  title: `Struggling to think of a good title`,
  children: (
    <div>
      <h1 className="text-xl font-bold">This is a `container` modal</h1>
      <p className="my-2 text-gray-500">
        It's pretty cool. I can put all kinds of custom html in here, like
      </p>
      <ul className="list-disc ml-6 text-gray-700">
        <li>Headings</li>
        <li>Paragraphs</li>
        <li>Unordered lists</li>
        <li>List items</li>
        <li>And so much more</li>
      </ul>
      <TextInput
        type="text"
        value=""
        setValue={() => {}}
        label="Like one of our custom inputs:"
        placeholder="Sorry, no editing"
        className="mt-3"
      />
      <p className="my-2 mt-5 text-gray-500">Or one of these cool things:</p>
      <div className="space-y-0.5">
        <SelectableListItem
          title={`Option one`}
          description={`This is the first option, and if ever you aren't sure which option to choos, the first one is generally a safe bet.`}
          selected={true}
          onClick={() => {}}
        />
        <SelectableListItem
          title={`Second option`}
          description={`I'd say maybe in like 20% of scennarios you want to click me. Usually that first guy up there is the best option.`}
          selected={false}
          onClick={() => {}}
        />
        <SelectableListItem
          title={`Option the third`}
          description={`Never EVER click the third option. Studies show that users who take the time to haul their cursor all the way down to the third option in a list like this get about 60% as much work done as the user who always just sticks with the top one.`}
          selected={false}
          onClick={() => alert(`And also frequently doubt authority`)}
        />
        <div className="flex justify-center mt-6 mb-4">
          <Logo />
        </div>
      </div>
    </div>
  ),
});

export default meta;
