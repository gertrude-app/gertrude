import { ComponentStory, ComponentMeta } from '@storybook/react';
import Modal from './Modal';

export default {
  title: `Dashboard/Core/Modal`,
  component: Modal,
  parameters: { layout: `fullscreen` },
} as ComponentMeta<typeof Modal>;

const Template: ComponentStory<typeof Modal> = (args) => <Modal {...args} />;

export const Default = Template.bind({});
Default.args = {
  type: `default`,
  title: `Just fyi...`,
  isOpen: true,
  onPrimaryClick: () => {},
  onDismiss: () => {},
  children: (
    <>
      Lorem ipsum dolor sit amet consectetur adipisicing elit. Dolorem aliquam autem eius,
      facere laudantium temporibus ea quasi.
    </>
  ),
  icon: 'info',
};

export const Destructive = Template.bind({});
Destructive.args = {
  ...Default.args,
  type: `destructive`,
  title: `NOOOOOOOOO!!!`,
  icon: 'exclamation-triangle',
  primaryButtonText: 'Delete',
};

export const Container = Template.bind({});
Container.args = {
  ...Default.args,
  type: `container`,
  title: `Cute little container`,
  icon: 'list',
  children: (
    <div className="flex flex-col space-y-3">
      <div>
        <h1 className="text-lg font-bold">Here's a thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">Here's another thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">Here's yet another thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">Surprise: another thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">You won't believe this, but...</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">Get this: another thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
      <div>
        <h1 className="text-lg font-bold">Thing thing thing thing</h1>
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Culpa facere laudantium
          unde eos quibusdam possimus id.
        </p>
      </div>
    </div>
  ),
};
