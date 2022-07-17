import Button from '@shared/Button';
import ColoredTag from '@shared/ColoredTag';
import DashboardPageHeading from '@shared/DashboardPageHeading';
import NoNotifications from '@shared/NoNotifications';
import TextInput from '@shared/TextInput';
import React from 'react';
import DashboardChrome from '../DashboardChrome';
import NotificationCard from '../NotificationCard';

const Profile: React.FC = () => {
  return (
    <DashboardChrome>
      <div className="py-10 px-7 sm:px-10 lg:px-12 xl:px-16">
        <DashboardPageHeading icon="user">Profile</DashboardPageHeading>
        <div className="flex flex-col md:flex-row mt-8">
          <div className="p-8 bg-gray-100 rounded-xl flex-grow md:mr-2 border">
            <h2 className="text-lg text-gray-900 mb-2">Email address:</h2>
            <TextInput
              type={'email'}
              label={''}
              value={'johndoe@example.com'}
              setValue={() => {}}
            />
          </div>
          <div className="px-8 py-4 bg-gray-100 rounded-xl md:ml-2 flex justify-between relative border mt-4 md:mt-0">
            <div className="flex justify-end items-start flex-col mr-8">
              <h2 className="font-bold text-gray-700">Basic plan</h2>
              <h3>
                <span className="text-gray-600">$</span>
                <span className="text-gray-700 text-3xl font-bold">10</span>
                <span className="text-gray-600 text-lg">/month</span>
              </h3>
              <a className="mt-1 text-sm text-blue-700 hover:text-blue-800 cursor-pointer transition duration-100">
                Manage subscription
              </a>
            </div>
            <ColoredTag type="active" className="absolute right-2 top-2" />
          </div>
        </div>
        <div className="mt-12">
          {/* <NoNotifications /> */}
          <h1 className="text-2xl font-bold">Notifications</h1>
          <div className="flex flex-col">
            <NotificationCard />
            <NotificationCard />
            <NotificationCard />
            <Button
              color="primary-violet"
              type="button"
              onClick={() => {}}
              className="self-center mt-8"
            >
              <i className="fa fa-plus mr-4" />
              New notification
            </Button>
          </div>
        </div>
      </div>
    </DashboardChrome>
  );
};

export default Profile;
