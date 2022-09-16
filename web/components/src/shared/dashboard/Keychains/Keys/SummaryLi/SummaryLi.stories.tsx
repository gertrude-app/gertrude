import { ComponentStory, ComponentMeta } from '@storybook/react';
import SummaryLi from './SummaryLi';

export default {
  title: `Dashboard/Keychains/Keys/SummaryLi`,
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
