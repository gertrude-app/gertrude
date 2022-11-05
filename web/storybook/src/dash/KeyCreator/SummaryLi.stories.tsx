import { ComponentStory, ComponentMeta } from '@storybook/react';
import { SummaryLi } from '@dash/components';

export default {
  title: `Dashboard/KeyCreator/SummaryLi`,
  component: SummaryLi,
} as ComponentMeta<typeof SummaryLi>;

const Template: ComponentStory<typeof SummaryLi> = () => (
  <ul>
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
    <SummaryLi prefix="Lorem ipsum" data="dolor sit amet" />
  </ul>
);

export const Default = Template.bind({});
