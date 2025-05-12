import React, { useState, useEffect, useRef } from 'react';
import { useLocation } from 'wouter';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { roundFormSchema, InsertRound, InsertCourse, InsertHole } from '@shared/schema';
import { useRounds } from '@/hooks/use-round';
import { 
  searchGolfCourses, 
  getGolfCourseById, 
  getFormattedTeeBoxes,
  convertToLocalCourse,
  formatHoleDetails
} from '@/lib/golfCourseApi';
import { GolfCourse, TeeBox } from '@/types/golfCourseApi';
import { Search } from 'lucide-react';
import { cn } from '@/lib/utils';

const NewRoundForm = ({ onCancel }: { onCancel: () => void }) => {
  const [_, navigate] = useLocation();
  const { createRound } = useRounds();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<GolfCourse[]>([]);
  const [selectedCourse, setSelectedCourse] = useState<GolfCourse | null>(null);
  const [availableTeeBoxes, setAvailableTeeBoxes] = useState<{ label: string; value: string; data: TeeBox }[]>([]);
  const [selectedTeeBox, setSelectedTeeBox] = useState<TeeBox | null>(null);
  const [openCourseSearch, setOpenCourseSearch] = useState(false);
  const [isSearching, setIsSearching] = useState(false);
  
  const currentDate = new Date().toISOString().split('T')[0];
  
  const form = useForm<InsertRound & { date: Date }>({
    resolver: zodResolver(roundFormSchema),
    defaultValues: {
      userId: 1, // Default user ID
      courseId: 1, // Will be replaced by actual course ID
      courseName: '',
      date: new Date(),
      weather: 'sunny',
      teeBox: '',
      teeBoxGender: 'male',
      courseRating: 0,
      slopeRating: 0, 
      totalYards: 0,
      totalScore: 0,
      relativeToPar: 0,
      fairwaysHit: 0,
      fairwaysTotal: 0,
      greensInRegulation: 0,
      totalPutts: 0
    }
  });
  
  // Search with debounce to avoid rate limits - using useRef for the timeout
  const searchTimeout = useRef<NodeJS.Timeout | null>(null);
  
  // Update searchQuery and trigger search with debounce
  const handleSearchInputChange = (value: string) => {
    setSearchQuery(value);
    
    // Clear any existing timeout to avoid multiple API calls
    if (searchTimeout.current) {
      clearTimeout(searchTimeout.current);
    }
    
    // Only search if the query is at least 3 characters
    if (value.length >= 3) {
      setIsSearching(true);
      
      // Set a significant delay to avoid hitting rate limits
      searchTimeout.current = setTimeout(async () => {
        try {
          console.log('Searching for courses with query:', value);
          const results = await searchGolfCourses(value);
          
          if (results.courses && Array.isArray(results.courses)) {
            console.log(`Setting search results: ${results.courses.length} courses found`);
            setSearchResults(results.courses);
          } else {
            setSearchResults([]);
            console.warn('No courses found or invalid response format', results);
          }
        } catch (error) {
          console.error('Error searching for courses:', error);
          setSearchResults([]);
        } finally {
          setIsSearching(false);
        }
      }, 1000); // Longer delay to avoid rate limits
    } else {
      setSearchResults([]);
    }
  };
  
  // When a course is selected, fetch its details and update form
  const handleCourseSelect = async (courseId: number) => {
    try {
      console.log(`Selecting course with ID: ${courseId}`);
      
      // First check if we already have this course in the search results
      let course = searchResults.find(c => c.id === courseId);
      
      if (!course) {
        try {
          // If not in search results, fetch it
          course = await getGolfCourseById(courseId);
        } catch (e) {
          console.error('Failed to fetch course details:', e);
          return; // Exit early - we can't proceed without a course
        }
      }
      
      // At this point we should have a course
      console.log(`Processing course: ${course.club_name}`);
      
      // Get tee boxes from the course object
      console.log(`Loading tee boxes for course: ${course.club_name}`);
      const teeBoxes = getFormattedTeeBoxes(course);
      console.log(`Found ${teeBoxes.length} tee boxes`);
      
      // Update state in a specific order
      setSelectedCourse(course);
      setAvailableTeeBoxes(teeBoxes);
      
      // Update form values
      form.setValue('courseId', course.id);
      form.setValue('courseName', `${course.club_name} - ${course.course_name || 'Main Course'}`);
      
      // Clear search once we've successfully processed the selection
      setSearchQuery('');
      
      // Show a success message to indicate course was selected
      console.log(`Course selected: ${course.club_name}`);
    } catch (error) {
      console.error('Error in course selection process:', error);
    }
  };
  
  // When a tee box is selected
  const handleTeeBoxSelect = (value: string) => {
    const [gender, teeName] = value.split('-');
    const selectedTeeBoxData = availableTeeBoxes.find(tb => tb.value === value)?.data;
    
    if (selectedTeeBoxData) {
      setSelectedTeeBox(selectedTeeBoxData);
      
      // Update form values with tee box details
      form.setValue('teeBox', teeName);
      form.setValue('teeBoxGender', gender as 'male' | 'female');
      form.setValue('courseRating', selectedTeeBoxData.course_rating);
      form.setValue('slopeRating', selectedTeeBoxData.slope_rating);
      form.setValue('totalYards', selectedTeeBoxData.total_yards);
    }
  };

  const onSubmit = async (data: InsertRound & { date: Date }) => {
    setIsSubmitting(true);
    try {
      // Make sure a course and tee box are selected
      if (!selectedCourse || !selectedTeeBox) {
        console.error('Course or tee box not selected');
        return;
      }
      
      // Format the date
      const formattedData = {
        ...data,
        date: typeof data.date === 'object' && data.date && 'toISOString' in data.date
          ? (data.date as Date).toISOString().split('T')[0] 
          : data.date
      };
      
      // Create the round
      const newRound = await createRound.mutateAsync(formattedData as any);
      
      // Handle hole creation automatically using the selected tee box data
      if (selectedTeeBox.holes && selectedTeeBox.holes.length > 0) {
        try {
          // Format the hole data for bulk insert
          const holeData = formatHoleDetails(selectedTeeBox.holes, selectedCourse.id, newRound.id);
          
          // Use the bulk insert endpoint to create all holes at once
          console.log(`Creating ${holeData.length} holes for round ${newRound.id}`);
          const response = await fetch(`/api/rounds/${newRound.id}/holes/bulk`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(holeData),
          });
          
          if (!response.ok) {
            console.error(`Failed to create holes: ${response.statusText}`);
          } else {
            console.log(`Successfully created ${holeData.length} holes for round ${newRound.id}`);
          }
        } catch (error) {
          console.error('Error creating holes:', error);
          // Continue anyway - we'll create holes as needed when the user navigates to each hole
        }
      }
      
      // Navigate to first hole of the new round
      navigate(`/round/${newRound.id}/hole/1`);
    } catch (error) {
      console.error('Error creating round:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Card className="bg-white rounded-xl shadow-md">
      <CardHeader>
        <div className="flex items-center">
          <Button 
            onClick={onCancel}
            variant="ghost" 
            size="icon" 
            className="mr-2"
          >
            <span className="material-icons">arrow_back</span>
          </Button>
          <CardTitle className="text-2xl font-display font-semibold text-neutral-darkest">New Round</CardTitle>
        </div>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
            <FormField
              control={form.control}
              name="courseName"
              render={({ field }) => (
                <FormItem className="flex flex-col">
                  <FormLabel>Golf Course</FormLabel>
                  <div className="space-y-2">
                    <FormControl>
                      <Input
                        placeholder="Search for a golf course"
                        type="text"
                        value={searchQuery}
                        onChange={(e) => handleSearchInputChange(e.target.value)}
                      />
                    </FormControl>
                    
                    {isSearching && (
                      <div className="flex items-center mt-2">
                        <div className="h-4 w-4 animate-spin rounded-full border-2 border-solid border-current border-r-transparent mr-2" />
                        <span className="text-sm">Searching...</span>
                      </div>
                    )}
                    
                    {searchResults.length > 0 && (
                      <div className="border rounded-md mt-2 max-h-60 overflow-y-auto bg-white">
                        <div className="p-2 text-xs font-semibold border-b">
                          {searchResults.length} course{searchResults.length !== 1 ? 's' : ''} found
                        </div>
                        <div className="divide-y">
                          {searchResults.map((course) => (
                            <div
                              key={course.id}
                              className="p-2 hover:bg-gray-100 cursor-pointer"
                              onClick={() => handleCourseSelect(course.id)}
                            >
                              <div className="font-medium">{course.club_name}</div>
                              <div className="text-xs text-gray-500">
                                {course.location?.city || ''}{course.location?.city ? ', ' : ''}{course.location?.country || ''}
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                    
                    {searchQuery.length > 2 && searchResults.length === 0 && !isSearching && (
                      <div className="text-sm text-gray-500 mt-2">
                        No courses found for "{searchQuery}"
                      </div>
                    )}
                  </div>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="date"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Date</FormLabel>
                  <FormControl>
                    <Input 
                      type="date" 
                      {...field}
                      value={typeof field.value === 'object' && field.value && 'toISOString' in field.value
                        ? (field.value as Date).toISOString().split('T')[0] 
                        : String(field.value)
                      }
                      onChange={(e) => field.onChange(new Date(e.target.value))}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="teeBox"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Tee Box</FormLabel>
                  <Select 
                    onValueChange={(value) => handleTeeBoxSelect(value)} 
                    defaultValue={field.value}
                    disabled={availableTeeBoxes.length === 0}
                  >
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder={availableTeeBoxes.length > 0 ? "Select tee box" : "Select a course first"} />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {availableTeeBoxes.length > 0 ? (
                        availableTeeBoxes.map((teeBox) => (
                          <SelectItem key={teeBox.value} value={teeBox.value}>
                            {teeBox.label}
                          </SelectItem>
                        ))
                      ) : (
                        <SelectItem disabled value="none">No tee boxes available</SelectItem>
                      )}
                    </SelectContent>
                  </Select>
                  {selectedTeeBox && (
                    <div className="mt-2 text-xs space-y-1 text-muted-foreground">
                      <div>Course Rating: {selectedTeeBox.course_rating}</div>
                      <div>Slope: {selectedTeeBox.slope_rating}</div>
                      <div>Total Yards: {selectedTeeBox.total_yards}</div>
                      <div>Par: {selectedTeeBox.par_total}</div>
                    </div>
                  )}
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <FormField
              control={form.control}
              name="weather"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Weather Conditions</FormLabel>
                  <div className="grid grid-cols-4 gap-2">
                    <Button
                      type="button"
                      variant={field.value === 'sunny' ? 'default' : 'outline'}
                      className={`px-3 py-2 h-auto ${field.value === 'sunny' ? 'bg-[#2D582A]' : ''}`}
                      onClick={() => field.onChange('sunny')}
                    >
                      <div className="flex flex-col items-center">
                        <span className="material-icons block mx-auto mb-1">wb_sunny</span>
                        <span className="text-xs">Sunny</span>
                      </div>
                    </Button>
                    <Button
                      type="button"
                      variant={field.value === 'cloudy' ? 'default' : 'outline'}
                      className={`px-3 py-2 h-auto ${field.value === 'cloudy' ? 'bg-[#2D582A]' : ''}`}
                      onClick={() => field.onChange('cloudy')}
                    >
                      <div className="flex flex-col items-center">
                        <span className="material-icons block mx-auto mb-1">cloud</span>
                        <span className="text-xs">Cloudy</span>
                      </div>
                    </Button>
                    <Button
                      type="button"
                      variant={field.value === 'rainy' ? 'default' : 'outline'}
                      className={`px-3 py-2 h-auto ${field.value === 'rainy' ? 'bg-[#2D582A]' : ''}`}
                      onClick={() => field.onChange('rainy')}
                    >
                      <div className="flex flex-col items-center">
                        <span className="material-icons block mx-auto mb-1">water_drop</span>
                        <span className="text-xs">Rainy</span>
                      </div>
                    </Button>
                    <Button
                      type="button"
                      variant={field.value === 'windy' ? 'default' : 'outline'}
                      className={`px-3 py-2 h-auto ${field.value === 'windy' ? 'bg-[#2D582A]' : ''}`}
                      onClick={() => field.onChange('windy')}
                    >
                      <div className="flex flex-col items-center">
                        <span className="material-icons block mx-auto mb-1">air</span>
                        <span className="text-xs">Windy</span>
                      </div>
                    </Button>
                  </div>
                  <FormMessage />
                </FormItem>
              )}
            />
            
            <Button 
              type="submit" 
              className="w-full bg-[#2D582A] text-white py-3 rounded-lg font-medium shadow-md hover:bg-[#224320]"
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <div className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-solid border-current border-r-transparent align-[-0.125em] motion-reduce:animate-[spin_1.5s_linear_infinite]" />
              ) : (
                'Start Round'
              )}
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  );
};

export default NewRoundForm;
