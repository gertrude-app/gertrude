import { ComponentStory, ComponentMeta } from '@storybook/react';
import Button from '../../../Button';
import SelectableListItem from '../../SelectableListItem';
import DashboardWidget from './DashboardWidget';

export default {
  title: `Dashboard/Dashboard/DashboardWidget`,
  component: DashboardWidget,
} as ComponentMeta<typeof DashboardWidget>;

const Template: ComponentStory<typeof DashboardWidget> = (args) => (
  <DashboardWidget {...args} />
);

export const Default = Template.bind({});
Default.args = { children: <h1>This is a DashboardWidget!</h1> };

export const MoreContent = Template.bind({});
MoreContent.args = {
  children: (
    <div>
      <h1>This is a DashboardWidget with more content!</h1>
      <div className="flex flex-row-reverse justify-between items-center">
        <div className="bg-violet-100 border-violet-200 border shadow-lg rounded-xl mt-4 p-4 max-w-xl my-12 flex justify-center items-center rotate-12 animate-pulse flex-grow">
          This is kinda cool, no?
        </div>
        <div>
          <Button
            className="mt-3"
            type="button"
            color="primary-violet"
            onClick={() => {}}
          >
            Button!
          </Button>
          <Button
            className="mt-3"
            type="button"
            color="secondary-white"
            onClick={() => {}}
          >
            Button!
          </Button>
          <Button
            className="mt-3"
            type="button"
            color="primary-violet"
            onClick={() => {}}
            small
          >
            Button!
          </Button>
          <Button
            className="mt-3"
            type="button"
            color="secondary-warning"
            onClick={() => {}}
            small
          >
            Button!
          </Button>
          <Button
            className="mt-3"
            type="button"
            color="secondary-white"
            onClick={() => {}}
            small
          >
            Button!
          </Button>
        </div>
      </div>
      <p className="my-8 text-sm pl-8 border-l-2 ml-8 border-l-gray-200 text-gray-500 italic font-serif">
        "Lorem ipsum dolor, sit amet consectetur adipisicing elit. Dicta, nobis ullam
        voluptatum nisi dolorum beatae. Quo consequatur ipsam sapiente eos, tempore labore
        eligendi. Est voluptas laboriosam nulla enim doloremque quod. Lorem, ipsum dolor
        sit amet consectetur adipisicing elit. Voluptate corporis animi velit inventore
        optio aut ipsam magnam quidem, saepe a pariatur sint tenetur dolorum voluptates
        iste illum autem expedita minus. Lorem ipsum dolor sit amet, consectetur
        adipisicing elit. Quis vero nobis eius quibusdam! Dolorum illo repudiandae facere
        earum est voluptatem, velit animi repellendus quam voluptatibus officiis nulla
        natus necessitatibus asperiores! Lorem ipsum dolor sit amet consectetur,
        adipisicing elit. Assumenda expedita voluptatibus sed vero, magni nemo ex earum
        consectetur adipisci repellendus eos molestiae asperiores architecto optio
        voluptas, eveniet similique quae impedit."
      </p>
      <SelectableListItem
        title={'Lorem ipsum'}
        description={
          'Lorem ipsum dolor, sit amet consectetur adipisicing elit. Dicta, nobis ullam voluptatum nisi dolorum beatae.'
        }
        selected={true}
        onClick={() => {}}
      />
      <SelectableListItem
        title={'Dolor sit'}
        description={
          'Lorem ipsum dolor, sit amet consectetur adipisicing elit. Dicta, nobis ullam voluptatum nisi dolorum beatae.'
        }
        selected={false}
        onClick={() => {}}
      />
      <SelectableListItem
        title={'Amet consectetur'}
        description={
          'Lorem ipsum dolor, sit amet consectetur adipisicing elit. Dicta, nobis ullam voluptatum nisi dolorum beatae.'
        }
        selected={false}
        onClick={() => {}}
      />
    </div>
  ),
};
