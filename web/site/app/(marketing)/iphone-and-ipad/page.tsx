import React from 'react';
import type { NextPage } from 'next';
import AdBlockingBlock from './AdBlockingBlock';
import AppleMapsBlock from './AppleMapsBlock';
import DownloadCTABlock from './DownloadCTABlock';
import GifBlockingBlock from './GifBlockingBlock';
import HeroBlock from './HeroBlock';
import MoreFeaturesBlock from './MoreFeaturesBlock';
import PricingBlock from './PricingBlock';
import SpotifyBlock from './SpotifyBlock';
import SpotlightBlock from './SpotlightBlock';
import TestimonialBlock from './TestimonialBlock';
import YouCompleteMeBlock from './YouCompleteMeBlock';
import { APP_STORE_URL } from './shared';
import ReviewsMarquee from '@/components/ReviewsMarquee';
import { createMetadata } from '@/lib/seo';

export const metadata = createMetadata(
  `Gertrude for iOS | Free Parental Controls to Block GIFs and Fix Screen Time Loopholes`,
  `Can't block GIFs in iMessage? Screen Time missing features? Gertrude is a free iOS parental control app that blocks #images GIF search, Spotlight web images, explicit Spotify artwork, and Apple Maps photos. Works alongside Screen Time.`,
);

const IPhoneAndIPadPage: NextPage = () => (
  <main>
    <HeroBlock />
    <YouCompleteMeBlock />
    <TestimonialBlock
      quote="Likely the greatest blessing an app has had on our lives."
      author="Austin944"
    />
    <GifBlockingBlock />
    <TestimonialBlock
      quote="Finally a way to block GIFS!!! Thank you, thank you, thank you!!!"
      author="HAAS1988"
    />
    <AppleMapsBlock />
    <TestimonialBlock
      quote="Saved my young son from looking at porn through the maps app. You are a lifesaver."
      author="GratefulMom55"
    />
    <SpotifyBlock />
    <SpotlightBlock />
    <TestimonialBlock
      quote="Thank you so much for helping us keep our kids safe. An answer to prayer."
      author="An answer to prayer"
    />
    <AdBlockingBlock />
    <MoreFeaturesBlock />
    <DownloadCTABlock />
    <ReviewsMarquee
      title="Parents love Gertrude for iOS"
      subtitle="See what parents are saying about our free iOS app."
      reviews={REVIEWS}
      rating="4.9"
      appStoreUrl={REVIEWS_URL}
    />
    <PricingBlock />
  </main>
);

export default IPhoneAndIPadPage;

const REVIEWS_URL = `${APP_STORE_URL}?see-all=reviews&platform=iphone`;

const REVIEWS = [
  [
    {
      title: `This is literally everything I've wanted`,
      body: `Likely the greatest blessing an app has had on our lives. I've reached out to developers, Apple, everyone I can begging for the ability to disable gifs. There is so much inappropriate content in that feature. And Apple maps images? That never occurred to me. And then to block ads on top of it? I couldn't be happier!!`,
      author: `Austin944`,
      date: `Oct 12, 2025`,
    },
    {
      title: `Every parent needs this`,
      body: `This app is meeting a great need since Apple has not allowed parents to properly protect their children. With the latest iOS updates, parents can no longer disable the gif images in texting. This app allows parents to decide if their child is not ready for that feature yet. Thank you.`,
      author: `Apple280`,
      date: `Jul 11, 2025`,
    },
    {
      title: `So happy for this!`,
      body: `Apple Screen Time has some helpful features, but there are a few glaring holes in its capabilities that allow kids to easily access adult images in really easy ways. Gertrude Blocker plugs the holes the Apple missed, and finally gives parents the ability to put a safe phone in their kids' hands.`,
      author: `Henderjay`,
      date: `Oct 24, 2024`,
    },
    {
      title: `Only app that combats Apple's loopholes`,
      body: `This is the only app I've been able to find that successfully blocks #images GIFs on the messaging app, notability, group me, ect! It's amazing I can't rave more. I can give my kids more access to things knowing there's no backdoors to harmful content!`,
      author: `4bkj`,
      date: `Jul 6, 2025`,
    },
    {
      title: `Porn-free kids' phones. Thank you!`,
      body: `We try to keep our kids' phones in a state where they are unable to view porn. Apple does a good job giving parents controls but they left a couple of holes! This is the only app that I know of that fills in those holes. Thank you!!`,
      author: `Rachel H.`,
      date: `Oct 24, 2024`,
    },
    {
      title: `Finally!!`,
      body: `Finally some help for parents! Ever since the iOS 17 update, there has been no way to block inappropriate GIFs. I have emailed Apple, written paper letters, posted on Apple message boards but to no avail. Thank you for creating this app!`,
      author: `Tiggy1234`,
      date: `Oct 26, 2024`,
    },
    {
      title: `Telling everyone I know`,
      body: `Thanks for fighting the good fight against this internet giant! May God bless you richly for it. I tell so many families about Gertrude.`,
      author: `Julia S.`,
      date: `Aug 19, 2025`,
      showStars: false,
    },
  ],
  [
    {
      title: `Amazing app to a very real need!`,
      body: `Thank you so much for helping us keep our kids safe. An answer to prayer. The app does just what I need it to do in conjunction with screen time.`,
      author: `An answer to prayer`,
      date: `Oct 31, 2025`,
    },
    {
      title: `A Life Saver`,
      body: `Not only does this app block explicit gifs and images but also blocks those annoying ads! If there was more stars to give I would!`,
      author: `Tonyj1234`,
      date: `Oct 22, 2025`,
    },
    {
      title: `Best app for parental controls`,
      body: `The only way to keep my kids safe. I wish Apple would add these features. Thank you!`,
      author: `Grateful_2025`,
      date: `Oct 24, 2025`,
    },
    {
      title: `Does what it says`,
      body: `Finally, a way to block #images GIFs in the Messages texting app! A glaring hole in Screen Time for over a year. Works perfect.`,
      author: `Sassy Wilhite`,
      date: `Oct 24, 2024`,
    },
    {
      title: `Great app`,
      body: `Blocks Gifs and more unwanted features that apple content restrictions have forgotten to block. Thank you for creating this app!`,
      author: `Gjurxinnkhd`,
      date: `Jul 22, 2025`,
    },
    {
      title: `Love it!`,
      body: `Im so happy about this app!! The only thing is it blocked all but three gifs. Two for sure need to be blocked and cant figure out how to get them blocked.`,
      author: `Arp0708`,
      date: `Nov 15, 2025`,
    },
    {
      title: `Using it on myself`,
      body: `Your app is wonderful. I ended up using it on my phone with supervision mode and I am so thankful.`,
      author: `Noah`,
      date: `May 6, 2025`,
      showStars: false,
    },
  ],
  [
    {
      title: `THANK YOU!!!`,
      body: `Saved my young son from looking at porn through the maps app. You are a lifesaver.`,
      author: `GratefulMom55`,
      date: `Apr 25, 2025`,
    },
    {
      title: `There is no alternative`,
      body: `Such a valuable app for parents who want to protect their children - even giving it 1000 stars wouldn't be enough.`,
      author: `nuhtufan12`,
      date: `Dec 12, 2025`,
    },
    {
      title: `Finally confident giving my kid a phone`,
      body: `We needed to give our 12 year old a phone for location sharing and messages. I was so hesitant until I found Gertrude. Setting it up was easy - I could cry. Being able to tell him nothing else would be on that phone and actually make it happen. A blessing for our family.`,
      author: `Tali M.`,
      date: `Mar 13, 2025`,
      showStars: false,
    },
    {
      title: `GIF Blocker!`,
      body: `Finally a way to block GIFS!!! Thank you, thank you, thank you!!!`,
      author: `HAAS1988`,
      date: `May 30, 2025`,
    },
    {
      title: `THANK YOU`,
      body: `Thank you for creating this app. This is a life saver.`,
      author: `sebvtg`,
      date: `Nov 1, 2024`,
    },
    {
      title: `Thankful`,
      body: `Works awesome! Thanks!`,
      author: `FrannyW567`,
      date: `Mar 6, 2025`,
    },
  ],
];
