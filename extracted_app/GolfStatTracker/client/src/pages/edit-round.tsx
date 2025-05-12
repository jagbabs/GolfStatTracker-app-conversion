import React, { useState, useEffect } from 'react';
import { useLocation } from 'wouter';
import { useRound } from '@/hooks/use-round';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  Select, 
  SelectContent, 
  SelectItem, 
  SelectTrigger, 
  SelectValue 
} from '@/components/ui/select';
import { format } from 'date-fns';
import { Round, roundFormSchema } from '@shared/schema';
import { zodResolver } from '@hookform/resolvers/zod';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { useToast } from '@/hooks/use-toast';

// Updated FormValues to match the schema changes
type FormValues = z.infer<typeof roundFormSchema>;

const EditRound = ({ params }: { params: { id: string } }) => {
  const roundId = parseInt(params.id, 10);
  const [, navigate] = useLocation();
  const { toast } = useToast();
  const roundHook = useRound(roundId);
  const { round = {} as Round } = roundHook;
  const updateRound = roundHook.updateRound;
  
  const form = useForm<FormValues>({
    resolver: zodResolver(roundFormSchema),
    values: {
      userId: round?.userId || 1,
      courseId: round?.courseId || 1,
      courseName: round?.courseName || '',
      date: round?.date || format(new Date(), 'yyyy-MM-dd'),
      teeBox: round?.teeBox || 'middle',
      weather: (round?.weather as any) || 'sunny',
      temperature: round?.temperature?.toString() || '20',
      windSpeed: round?.windSpeed?.toString() || '5',
      notes: round?.notes || '',
    }
  });
  
  // Update form values when round data is loaded
  useEffect(() => {
    if (round?.id) {
      form.reset({
        userId: round.userId,
        courseId: round.courseId,
        courseName: round.courseName,
        date: round.date,
        teeBox: round.teeBox || '',
        weather: (round.weather as any) || 'sunny',
        temperature: round.temperature?.toString() || '20',
        windSpeed: round.windSpeed?.toString() || '5',
        notes: round.notes || '',
      });
    }
  }, [round, form]);
  
  const onSubmit = (data: FormValues) => {
    updateRound.mutate({
      ...data,
      id: roundId,
      temperature: parseInt(data.temperature as string),
      windSpeed: parseInt(data.windSpeed as string),
    }, {
      onSuccess: () => {
        toast({
          title: 'Round Updated',
          description: 'Your round has been updated successfully',
        });
        navigate('/rounds');
      },
    });
  };
  
  if (!round?.id) {
    return (
      <div className="p-4">
        <Card className="bg-white rounded-xl shadow-md p-4">
          <CardContent className="p-0">
            <h2 className="text-xl font-medium mb-4">Loading round data...</h2>
          </CardContent>
        </Card>
      </div>
    );
  }
  
  return (
    <div className="p-4">
      <Card className="bg-white rounded-xl shadow-md">
        <CardContent className="p-5">
          <h2 className="text-xl font-medium mb-4">Edit Round Details</h2>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <Label htmlFor="courseName">Course Name</Label>
              <Input 
                id="courseName" 
                {...form.register('courseName')}
                defaultValue={round.courseName} 
              />
              {form.formState.errors.courseName && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.courseName.message}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="date">Date Played</Label>
              <Input 
                id="date" 
                type="date" 
                {...form.register('date')}
                defaultValue={typeof round.date === 'string' ? round.date : format(new Date(), 'yyyy-MM-dd')}
              />
              {form.formState.errors.date && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.date.message}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="teeBox">Tees Played</Label>
              <Select 
                defaultValue={round.teeBox || ""} 
                onValueChange={(value) => form.setValue('teeBox', value)}
              >
                <SelectTrigger id="teeBox">
                  <SelectValue placeholder="Select tees" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="championship">Championship</SelectItem>
                  <SelectItem value="back">Back</SelectItem>
                  <SelectItem value="middle">Middle</SelectItem>
                  <SelectItem value="forward">Forward</SelectItem>
                </SelectContent>
              </Select>
              {form.formState.errors.teeBox && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.teeBox.message}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="weather">Weather Conditions</Label>
              <Select 
                defaultValue={round.weather || ""} 
                onValueChange={(value: string) => form.setValue('weather', value as any)}
              >
                <SelectTrigger id="weather">
                  <SelectValue placeholder="Select weather" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="sunny">Sunny</SelectItem>
                  <SelectItem value="cloudy">Cloudy</SelectItem>
                  <SelectItem value="rainy">Rainy</SelectItem>
                  <SelectItem value="windy">Windy</SelectItem>
                  <SelectItem value="stormy">Stormy</SelectItem>
                </SelectContent>
              </Select>
              {form.formState.errors.weather && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.weather.message}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="temperature">Temperature (°C)</Label>
              <Input
                id="temperature"
                type="number"
                {...form.register('temperature')}
                defaultValue={round.temperature}
              />
              {form.formState.errors.temperature && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.temperature.message?.toString()}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="windSpeed">Wind Speed (mph)</Label>
              <Input
                id="windSpeed"
                type="number"
                {...form.register('windSpeed')}
                defaultValue={round.windSpeed}
              />
              {form.formState.errors.windSpeed && (
                <p className="text-red-500 text-sm mt-1">{form.formState.errors.windSpeed.message?.toString()}</p>
              )}
            </div>
            
            <div>
              <Label htmlFor="notes">Notes</Label>
              <Input
                id="notes"
                {...form.register('notes')}
                defaultValue={round.notes || ""}
                placeholder="Add notes about this round"
              />
            </div>
            
            <div className="flex justify-between pt-4">
              <Button type="button" variant="outline" onClick={() => navigate('/rounds')}>
                Cancel
              </Button>
              <Button type="submit" className="bg-[#2D582A]">
                Save Changes
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
};

export default EditRound;