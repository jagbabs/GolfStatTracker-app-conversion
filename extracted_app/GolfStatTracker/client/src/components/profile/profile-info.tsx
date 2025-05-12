import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useQuery, useMutation } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { queryClient } from '@/lib/queryClient';
import { User } from '@shared/schema';

const profileFormSchema = z.object({
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  email: z.string().email("Please enter a valid email"),
  handicap: z.number().min(0).max(54).optional(),
  homeCourse: z.string().optional()
});

type ProfileFormValues = z.infer<typeof profileFormSchema>;

const ProfileInfo = () => {
  const [isEditing, setIsEditing] = useState(false);
  
  const { data: user, isLoading } = useQuery<User>({
    queryKey: ['/api/users/me'],
  });

  const updateProfile = useMutation({
    mutationFn: async (data: Partial<User>) => {
      const response = await apiRequest('PUT', '/api/users/me', data);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/users/me'] });
      setIsEditing(false);
    }
  });

  const form = useForm<ProfileFormValues>({
    resolver: zodResolver(profileFormSchema),
    defaultValues: {
      firstName: user?.firstName || '',
      lastName: user?.lastName || '',
      email: user?.email || '',
      handicap: user?.handicap || 0,
      homeCourse: user?.homeCourse || ''
    }
  });

  const onSubmit = (data: ProfileFormValues) => {
    updateProfile.mutate(data);
  };

  // Default user data if not loaded yet
  const userData = user || {
    firstName: 'John',
    lastName: 'Doe',
    email: 'john.doe@example.com',
    handicap: 12.4,
    homeCourse: 'Pebble Beach Golf Links',
    createdAt: new Date('2023-03-01')
  };

  const getInitials = () => {
    if (userData.firstName && userData.lastName) {
      return `${userData.firstName[0]}${userData.lastName[0]}`;
    } else if (userData.username) {
      return userData.username.substring(0, 2).toUpperCase();
    }
    return 'JD';
  };

  const getJoinDate = () => {
    if (userData.createdAt) {
      const date = new Date(userData.createdAt);
      return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
    }
    return 'March 2023';
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader>
        <CardTitle className="font-display font-medium text-lg">Your Profile</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center mb-6">
          <div className="w-16 h-16 rounded-full bg-[#2D582A] flex items-center justify-center text-white text-2xl font-medium mr-4">
            {getInitials()}
          </div>
          <div>
            <h3 className="font-medium text-lg">{userData.firstName} {userData.lastName}</h3>
            <p className="text-neutral-dark">Joined {getJoinDate()}</p>
          </div>
          <Dialog open={isEditing} onOpenChange={setIsEditing}>
            <DialogTrigger asChild>
              <Button 
                variant="ghost" 
                size="icon" 
                className="ml-auto p-2 text-[#2D582A]"
              >
                <span className="material-icons">edit</span>
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>Edit Profile</DialogTitle>
              </DialogHeader>
              <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                  <FormField
                    control={form.control}
                    name="firstName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>First Name</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="lastName"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Last Name</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Email</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="handicap"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Handicap</FormLabel>
                        <FormControl>
                          <Input 
                            type="number" 
                            step="0.1" 
                            min="0" 
                            max="54" 
                            {...field} 
                            onChange={(e) => field.onChange(parseFloat(e.target.value))}
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={form.control}
                    name="homeCourse"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Home Course</FormLabel>
                        <FormControl>
                          <Input {...field} />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <div className="flex justify-end gap-2">
                    <Button 
                      type="button" 
                      variant="outline"
                      onClick={() => setIsEditing(false)}
                    >
                      Cancel
                    </Button>
                    <Button type="submit">Save Changes</Button>
                  </div>
                </form>
              </Form>
            </DialogContent>
          </Dialog>
        </div>
        
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-neutral-dark mb-1">Email</label>
            <p className="font-medium">{userData.email}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-dark mb-1">Handicap</label>
            <p className="font-medium">{userData.handicap}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-neutral-dark mb-1">Home Course</label>
            <p className="font-medium">{userData.homeCourse}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default ProfileInfo;
