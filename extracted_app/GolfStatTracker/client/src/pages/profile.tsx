import React, { useState } from 'react';
import { useLocation } from 'wouter';
import ProfileInfo from '@/components/profile/profile-info';
import AppSettings from '@/components/profile/app-settings';
import ConnectedAccounts from '@/components/profile/connected-accounts';
import ClubManagement from '@/components/profile/club-management';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

const Profile = () => {
  const [, navigate] = useLocation();
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState('profile');
  
  const handleSignOut = () => {
    // API call to sign out would go here
    toast({
      title: "Signed Out",
      description: "You have been successfully signed out.",
    });
    navigate('/');
  };

  return (
    <div className="p-4">
      <div className="mb-6">
        <h2 className="text-2xl font-display font-semibold text-neutral-darkest mb-2">Your Profile</h2>
        <p className="text-neutral-dark">Manage your account and preferences</p>
      </div>
      
      <Tabs value={activeTab} onValueChange={setActiveTab} className="mb-6">
        <TabsList className="w-full mb-4">
          <TabsTrigger value="profile" className="flex-1">Profile</TabsTrigger>
          <TabsTrigger value="clubs" className="flex-1">Clubs</TabsTrigger>
          <TabsTrigger value="settings" className="flex-1">Settings</TabsTrigger>
        </TabsList>
        
        <TabsContent value="profile">
          <ProfileInfo />
          <ConnectedAccounts />
        </TabsContent>
        
        <TabsContent value="clubs">
          <ClubManagement />
        </TabsContent>
        
        <TabsContent value="settings">
          <AppSettings />
        </TabsContent>
      </Tabs>
      
      <div className="py-4">
        <Button 
          variant="outline"
          className="w-full border border-error text-error py-3 rounded-lg font-medium hover:bg-error hover:bg-opacity-10"
          onClick={handleSignOut}
        >
          Sign Out
        </Button>
      </div>
    </div>
  );
};

export default Profile;
