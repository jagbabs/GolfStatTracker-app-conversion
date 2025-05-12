import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useClubs } from '@/hooks/use-clubs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Club, clubFormSchema } from '@shared/schema';

const ClubDistances = () => {
  const { clubs, isLoading, updateClub } = useClubs();
  const [isEditing, setIsEditing] = useState(false);
  const [selectedClub, setSelectedClub] = useState<Club | null>(null);

  // Get the max distance to normalize the visualization
  const maxDistance = Math.max(...clubs.map(club => club.distance || 0), 1);

  const form = useForm({
    resolver: zodResolver(clubFormSchema),
    defaultValues: {
      userId: 1, // Default user ID
      name: '',
      type: 'driver',
      distance: 0,
      isInBag: true
    }
  });

  const onEditClub = (club: Club) => {
    setSelectedClub(club);
    form.reset({
      userId: club.userId,
      name: club.name,
      type: club.type,
      distance: club.distance,
      isInBag: club.isInBag
    });
  };

  const onSubmit = (data: any) => {
    if (selectedClub) {
      updateClub.mutate({
        ...selectedClub,
        ...data,
        distance: Number(data.distance)
      });
      setSelectedClub(null);
    }
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="font-display font-medium text-lg">Your Club Distances</CardTitle>
        <Button
          variant="ghost"
          className="text-[#2D582A] text-sm font-medium"
          onClick={() => setIsEditing(!isEditing)}
        >
          {isEditing ? 'Done' : 'Edit'}
        </Button>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="py-8 flex items-center justify-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
          </div>
        ) : clubs.length === 0 ? (
          <div className="text-center py-6 text-neutral-dark">
            <p>No clubs added yet.</p>
            <Button variant="outline" className="mt-2">
              Add your first club
            </Button>
          </div>
        ) : (
          <div className="space-y-3">
            {clubs.map((club) => (
              <div key={club.id} className="flex items-center justify-between">
                <span className="font-medium w-16">{club.name}</span>
                <div className="flex-grow mx-4">
                  <div className="h-2 bg-neutral-light rounded-full">
                    <div 
                      className="h-2 bg-[#2D582A] rounded-full" 
                      style={{ width: `${(club.distance || 0) / maxDistance * 100}%` }}
                    ></div>
                  </div>
                </div>
                <div className="flex items-center">
                  <span className="text-right w-16">{club.distance} yds</span>
                  {isEditing && (
                    <Dialog>
                      <DialogTrigger asChild>
                        <Button 
                          variant="ghost" 
                          size="icon" 
                          className="ml-2 h-8 w-8 text-neutral-dark"
                          onClick={() => onEditClub(club)}
                        >
                          <span className="material-icons">edit</span>
                        </Button>
                      </DialogTrigger>
                      <DialogContent>
                        <DialogHeader>
                          <DialogTitle>Edit Club Distance</DialogTitle>
                        </DialogHeader>
                        <Form {...form}>
                          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                            <FormField
                              control={form.control}
                              name="name"
                              render={({ field }) => (
                                <FormItem>
                                  <FormLabel>Club Name</FormLabel>
                                  <FormControl>
                                    <Input {...field} />
                                  </FormControl>
                                  <FormMessage />
                                </FormItem>
                              )}
                            />
                            <FormField
                              control={form.control}
                              name="type"
                              render={({ field }) => (
                                <FormItem>
                                  <FormLabel>Club Type</FormLabel>
                                  <Select 
                                    onValueChange={field.onChange} 
                                    defaultValue={field.value}
                                  >
                                    <FormControl>
                                      <SelectTrigger>
                                        <SelectValue placeholder="Select a club type" />
                                      </SelectTrigger>
                                    </FormControl>
                                    <SelectContent>
                                      <SelectItem value="driver">Driver</SelectItem>
                                      <SelectItem value="wood">Wood</SelectItem>
                                      <SelectItem value="iron">Iron</SelectItem>
                                      <SelectItem value="wedge">Wedge</SelectItem>
                                      <SelectItem value="putter">Putter</SelectItem>
                                    </SelectContent>
                                  </Select>
                                  <FormMessage />
                                </FormItem>
                              )}
                            />
                            <FormField
                              control={form.control}
                              name="distance"
                              render={({ field }) => (
                                <FormItem>
                                  <FormLabel>Distance (yards)</FormLabel>
                                  <FormControl>
                                    <Input {...field} type="number" />
                                  </FormControl>
                                  <FormMessage />
                                </FormItem>
                              )}
                            />
                            <div className="flex justify-end gap-2">
                              <Button 
                                type="button" 
                                variant="outline"
                                onClick={() => setSelectedClub(null)}
                              >
                                Cancel
                              </Button>
                              <Button type="submit">Save Changes</Button>
                            </div>
                          </form>
                        </Form>
                      </DialogContent>
                    </Dialog>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default ClubDistances;
