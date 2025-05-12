import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { useClubs } from '@/hooks/use-clubs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Club } from '@shared/schema';

const clubFormSchema = z.object({
  name: z.string().min(1, "Club name is required"),
  type: z.string().min(1, "Club type is required"),
  distance: z.number().min(0, "Distance cannot be negative"),
  isInBag: z.boolean().default(true),
  userId: z.number().default(1)
});

type ClubFormValues = z.infer<typeof clubFormSchema>;

const ClubManagement = () => {
  const { clubs, createClub, updateClub, deleteClub } = useClubs();
  const [isAddingClub, setIsAddingClub] = useState(false);
  const [selectedClub, setSelectedClub] = useState<Club | null>(null);

  const form = useForm<ClubFormValues>({
    resolver: zodResolver(clubFormSchema),
    defaultValues: {
      name: '',
      type: 'driver',
      distance: 0,
      isInBag: true,
      userId: 1
    }
  });

  const onSubmit = (data: ClubFormValues) => {
    if (selectedClub) {
      updateClub.mutate({
        ...data,
        id: selectedClub.id
      } as Club);
    } else {
      createClub.mutate(data);
    }
    setIsAddingClub(false);
    setSelectedClub(null);
    form.reset();
  };

  const handleEditClub = (club: Club) => {
    setSelectedClub(club);
    form.reset({
      name: club.name,
      type: club.type,
      distance: club.distance,
      isInBag: club.isInBag,
      userId: club.userId
    });
    setIsAddingClub(true);
  };

  const handleToggleInBag = (club: Club) => {
    updateClub.mutate({
      ...club,
      isInBag: !club.isInBag
    });
  };

  const handleDeleteClub = (clubId: number) => {
    if (confirm('Are you sure you want to delete this club?')) {
      deleteClub.mutate(clubId);
    }
  };

  // Group clubs by type for display
  const clubsByType: Record<string, Club[]> = {
    driver: [],
    wood: [],
    hybrid: [],
    iron: [],
    wedge: [],
    putter: []
  };

  clubs.forEach(club => {
    if (clubsByType[club.type]) {
      clubsByType[club.type].push(club);
    } else {
      clubsByType.other = clubsByType.other || [];
      clubsByType.other.push(club);
    }
  });

  const typeLabels: Record<string, string> = {
    driver: 'Drivers',
    wood: 'Woods',
    hybrid: 'Hybrids',
    iron: 'Irons',
    wedge: 'Wedges',
    putter: 'Putters',
    other: 'Other Clubs'
  };

  return (
    <Card className="bg-white rounded-xl shadow-md mb-6">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="font-display font-medium text-lg">Club Management</CardTitle>
        <Dialog open={isAddingClub} onOpenChange={setIsAddingClub}>
          <DialogTrigger asChild>
            <Button 
              variant="outline" 
              className="text-[#2D582A] border-[#2D582A]"
              onClick={() => {
                setSelectedClub(null);
                form.reset({
                  name: '',
                  type: 'driver',
                  distance: 0,
                  isInBag: true,
                  userId: 1
                });
              }}
            >
              <span className="material-icons mr-1 text-sm">add</span>
              Add Club
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>
                {selectedClub ? 'Edit Club' : 'Add New Club'}
              </DialogTitle>
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
                        <Input placeholder="Driver, 3 Wood, 7 Iron, etc." {...field} />
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
                        value={field.value}
                      >
                        <FormControl>
                          <SelectTrigger>
                            <SelectValue placeholder="Select club type" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent>
                          <SelectItem value="driver">Driver</SelectItem>
                          <SelectItem value="wood">Wood</SelectItem>
                          <SelectItem value="hybrid">Hybrid</SelectItem>
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
                      <FormLabel>Typical Distance (yards)</FormLabel>
                      <FormControl>
                        <Input 
                          type="number" 
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
                  name="isInBag"
                  render={({ field }) => (
                    <FormItem className="flex flex-row items-center justify-between p-3 border rounded-lg">
                      <div>
                        <FormLabel>In My Bag</FormLabel>
                      </div>
                      <FormControl>
                        <Switch 
                          checked={field.value} 
                          onCheckedChange={field.onChange}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
                <div className="flex justify-end gap-2 pt-2">
                  <Button 
                    type="button" 
                    variant="outline"
                    onClick={() => {
                      setIsAddingClub(false);
                      setSelectedClub(null);
                    }}
                  >
                    Cancel
                  </Button>
                  <Button type="submit">
                    {selectedClub ? 'Update Club' : 'Add Club'}
                  </Button>
                </div>
              </form>
            </Form>
          </DialogContent>
        </Dialog>
      </CardHeader>

      <CardContent>
        <h3 className="text-neutral-dark mb-2 font-medium">My Bag Setup</h3>
        
        {Object.entries(clubsByType).map(([type, clubsOfType]) => (
          clubsOfType.length > 0 && (
            <div key={type} className="mb-4">
              <h4 className="text-sm font-semibold text-neutral-dark mb-2">{typeLabels[type] || type}</h4>
              
              <div className="space-y-2">
                {clubsOfType.map(club => (
                  <div 
                    key={club.id} 
                    className={`flex items-center justify-between p-3 rounded-lg border ${club.isInBag ? 'border-green-200 bg-green-50' : 'border-neutral-200'}`}
                  >
                    <div className="flex items-center">
                      <div className={`w-3 h-3 rounded-full mr-3 ${club.isInBag ? 'bg-green-500' : 'bg-neutral-300'}`}></div>
                      <div>
                        <div className="font-medium">{club.name}</div>
                        <div className="text-sm text-neutral-dark">{club.distance} yards</div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2">
                      <Switch 
                        checked={club.isInBag} 
                        onCheckedChange={() => handleToggleInBag(club)}
                      />
                      <Button 
                        variant="ghost" 
                        size="icon" 
                        className="h-8 w-8 text-neutral-dark"
                        onClick={() => handleEditClub(club)}
                      >
                        <span className="material-icons" style={{ fontSize: '1rem' }}>edit</span>
                      </Button>
                      <Button 
                        variant="ghost" 
                        size="icon" 
                        className="h-8 w-8 text-neutral-dark"
                        onClick={() => handleDeleteClub(club.id)}
                      >
                        <span className="material-icons" style={{ fontSize: '1rem' }}>delete</span>
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )
        ))}
        
        {clubs.length === 0 && (
          <div className="text-center py-8 text-neutral-dark">
            <p>No clubs added yet. Click "Add Club" to get started.</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export default ClubManagement;