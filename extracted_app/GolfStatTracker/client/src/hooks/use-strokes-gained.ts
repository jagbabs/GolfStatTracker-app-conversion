import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { queryClient } from '@/lib/queryClient';
import { StrokesGained, InsertStrokesGained } from '@shared/schema';
import { useToast } from '@/hooks/use-toast';
import { filterByTimePeriod } from '@/lib/utils';

// Calculate strokes gained based on shot data
export function calculateStrokesGained(
  shotType: string,
  distanceToTarget: number | null, 
  outcome: string, 
  par: number
) {
  // Baseline values based on real golf data
  // These values represent the expected number of strokes to hole out from various situations
  const baselineValues = {
    // Expected strokes from tee based on distance
    tee: {
      100: 2.92,
      120: 2.99,
      140: 2.97,
      160: 2.99,
      180: 3.05,
      200: 3.12,
      220: 3.17,
      240: 3.25,
      260: 3.45,
      280: 3.65,
      300: 3.71,
      320: 3.79,
      340: 3.86,
      360: 3.92,
      380: 3.96,
      400: 3.99,
      420: 4.02,
      440: 4.08,
      460: 4.17,
      480: 4.28,
      500: 4.41,
      520: 4.54,
      540: 4.65,
      560: 4.74,
      580: 4.79,
      600: 4.82,
    },
    // Expected strokes from fairway based on distance
    fairway: {
      20: 2.40,
      40: 2.60,
      60: 2.70,
      80: 2.75,
      100: 2.80,
      120: 2.85,
      140: 2.91,
      160: 2.98,
      180: 3.08,
      200: 3.19,
      220: 3.32,
      240: 3.45,
      260: 3.58,
      280: 3.69,
      300: 3.78,
      320: 3.84,
      340: 3.88,
      360: 3.95,
      380: 4.03,
      400: 4.11,
      420: 4.15,
      440: 4.20,
      460: 4.29,
      480: 4.40,
      500: 4.53,
      520: 4.66,
      540: 4.78,
      560: 4.86,
      580: 4.91,
      600: 4.94,
    },
    // Expected strokes from rough based on distance
    rough: {
      20: 2.59,
      40: 2.78,
      60: 2.91,
      80: 2.96,
      100: 3.02,
      120: 3.08,
      140: 3.15,
      160: 3.23,
      180: 3.31,
      200: 3.42,
      220: 3.53,
      240: 3.64,
      260: 3.74,
      280: 3.83,
      300: 3.90,
      320: 3.95,
      340: 4.02,
      360: 4.11,
      380: 4.21,
      400: 4.30,
      420: 4.34,
      440: 4.39,
      460: 4.48,
      480: 4.59,
      500: 4.72,
      520: 4.85,
      540: 4.97,
      560: 5.05,
      580: 5.10,
      600: 5.13,
    },
    // Expected strokes from sand based on distance
    sand: {
      20: 2.53,
      40: 2.82,
      60: 3.15,
      80: 3.24,
      100: 3.23,
      120: 3.21,
      140: 3.22,
      160: 3.28,
      180: 3.40,
      200: 3.55,
      220: 3.70,
      240: 3.84,
      260: 3.93,
      280: 4.00,
      300: 4.04,
      320: 4.12,
      340: 4.26,
      360: 4.41,
      380: 4.55,
      400: 4.69,
      420: 4.73,
      440: 4.78,
      460: 4.87,
      480: 4.98,
      500: 5.11,
      520: 5.24,
      540: 5.36,
      560: 5.44,
      580: 5.49,
      600: 5.52,
    },
    // Expected strokes from recovery areas
    recovery: {
      100: 3.80,
      120: 3.78,
      140: 3.80,
      160: 3.81,
      180: 3.82,
      200: 3.87,
      220: 3.92,
      240: 3.97,
      260: 4.03,
      280: 4.10,
      300: 4.20,
      320: 4.31,
      340: 4.44,
      360: 4.56,
      380: 4.66,
      400: 4.75,
      420: 4.79,
      440: 4.84,
      460: 4.93,
      480: 5.04,
      500: 5.17,
      520: 5.30,
      540: 5.42,
      560: 5.50,
      580: 5.55,
      600: 5.58,
    },
    // Expected strokes on the green based on distance (in feet)
    green: {
      3: 1.04,
      4: 1.13,
      5: 1.23,
      6: 1.34,
      7: 1.42,
      8: 1.50,
      9: 1.56,
      10: 1.61,
      15: 1.78,
      20: 1.87,
      30: 1.98,
      40: 2.06, 
      50: 2.14,
      60: 2.21,
      90: 2.40,
    }
  };

  if (!distanceToTarget) return 0;

  // Helper function to get the nearest baseline value
  const getNearestValue = (distance: number, location: Record<string, number>) => {
    // Find the nearest distance bracket
    const distances = Object.keys(location).map(Number).sort((a, b) => a - b);
    
    // Find the closest distance value (rounding down to previous bracket)
    let closestDistance = distances[0];
    for (const dist of distances) {
      if (dist <= distance) {
        closestDistance = dist;
      } else {
        break;
      }
    }
    
    return location[closestDistance.toString()];
  };

  // For tee shots
  if (shotType === 'tee') {
    // Get expected strokes from this distance
    const expectedStrokes = getNearestValue(distanceToTarget, baselineValues.tee);
    
    // Calculate strokes gained based on where the ball landed and its new location
    let nextShotExpectedStrokes = 0;
    
    if (outcome === 'fairway') {
      // Get expected strokes for the next shot from fairway
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.7, baselineValues.fairway);
      return expectedStrokes - nextShotExpectedStrokes - 1; // -1 for the shot just taken
    } 
    else if (outcome === 'rough') {
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.7, baselineValues.rough);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'bunker') {
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.7, baselineValues.sand);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'green') {
      // If somehow driver to green, big advantage
      nextShotExpectedStrokes = getNearestValue(20, baselineValues.green); // Assume 20 feet putt
      return expectedStrokes - nextShotExpectedStrokes - 1;
    }
    else if (outcome === 'hazard') {
      return -1.0; // Penalty
    }
    else if (outcome === 'ob') {
      return -2.0; // Stroke and distance penalty
    }
    
    return 0; // Default if outcome not recognized
  } 
  
  // For approach shots
  else if (shotType === 'approach') {
    // Different sources based on where the shot is played from
    let sourceLocation: Record<string, number>;
    if (outcome === 'fairway') sourceLocation = baselineValues.fairway;
    else if (outcome === 'rough') sourceLocation = baselineValues.rough;
    else if (outcome === 'bunker' || outcome === 'sand') sourceLocation = baselineValues.sand;
    else if (outcome === 'recovery') sourceLocation = baselineValues.recovery;
    else sourceLocation = baselineValues.fairway; // Default to fairway
    
    // Get expected strokes from this distance
    const expectedStrokes = getNearestValue(distanceToTarget, sourceLocation);
    
    // Calculate next shot expectation based on outcome
    let nextShotExpectedStrokes = 0;
    
    if (outcome === 'green') {
      // If on green, next shot is a putt
      // Convert from yards to feet (very rough approximation for putt distance)
      const puttDistanceInFeet = Math.min(90, distanceToTarget * 0.3); // Scale down and cap at 90 feet
      nextShotExpectedStrokes = getNearestValue(puttDistanceInFeet, baselineValues.green);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'fairway') {
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.5, baselineValues.fairway);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'rough') {
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.5, baselineValues.rough);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'bunker' || outcome === 'sand') {
      nextShotExpectedStrokes = getNearestValue(distanceToTarget * 0.5, baselineValues.sand);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    }
    else if (outcome === 'hazard') {
      return -1.0; // Penalty
    }
    else if (outcome === 'ob') {
      return -2.0; // Stroke and distance penalty
    }
    
    return 0;
  } 
  
  // For short game (chips and bunker shots)
  else if (shotType === 'chip' || shotType === 'bunker') {
    // Source depends on shot type
    const sourceLocation: Record<string, number> = shotType === 'bunker' ? baselineValues.sand : baselineValues.recovery;
    
    // Expected shots for chip or bunker shot
    // Since our baseline data starts at 20 yards, use that as minimum
    const expectedStrokes = getNearestValue(Math.max(20, distanceToTarget), sourceLocation);
    
    if (outcome === 'green') {
      // If the chip/bunker shot is on the green, outcome depends on proximity
      // Convert yards to feet for putting (approximate)
      const puttDistanceInFeet = Math.min(distanceToTarget * 3, 60); // Cap at 60 feet for a chip
      const nextShotExpectedStrokes = getNearestValue(puttDistanceInFeet, baselineValues.green);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'holed') {
      // Holed shots are excellent
      return expectedStrokes - 1; // Saved all expected strokes except the one taken
    }
    else {
      // Missing with a chip or bunker shot is bad
      return -0.5;
    }
  } 
  
  // For putts
  else if (shotType === 'putt') {
    // For putts, expected strokes depend on the length in feet
    const expectedStrokes = getNearestValue(distanceToTarget, baselineValues.green);
    
    if (outcome === 'holed') {
      return expectedStrokes - 1; // Gained whatever was expected minus the one stroke taken
    } 
    else if (outcome === 'good') {
      // Good lag putt left close for next putt
      const nextPuttDistance = 2; // Assume left about 2 feet
      const nextShotExpectedStrokes = getNearestValue(nextPuttDistance, baselineValues.green);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    } 
    else if (outcome === 'poor') {
      // Poor putt left work to do
      const nextPuttDistance = 5; // Assume left about 5 feet
      const nextShotExpectedStrokes = getNearestValue(nextPuttDistance, baselineValues.green);
      return expectedStrokes - nextShotExpectedStrokes - 1;
    }
    
    return 0; // Default for putts
  }
  
  return 0; // Default catch-all
}

// Hook for accessing strokes gained data
export function useStrokesGained(userId = 1) {
  const { toast } = useToast();
  const [timePeriod, setTimePeriod] = useState<number | null>(null); // null means all time
  
  // Get all strokes gained data
  const {
    data: strokesGained = [],
    isLoading,
    isError,
    error
  } = useQuery<StrokesGained[]>({
    queryKey: ['/api/strokes-gained'],
  });
  
  // Filter data based on time period if selected
  const filteredData = timePeriod 
    ? filterByTimePeriod(strokesGained, 'date', timePeriod) 
    : strokesGained;
  
  // Get strokes gained for a specific user
  const userStrokesGained = filteredData.filter(sg => sg.userId === userId);
  
  // Create new strokes gained entry
  const createStrokesGained = useMutation({
    mutationFn: async (data: InsertStrokesGained) => {
      const response = await apiRequest('POST', '/api/strokes-gained', data);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/strokes-gained'] });
      toast({
        title: 'Strokes gained updated',
        description: 'Your strokes gained data has been saved successfully.',
      });
    },
    onError: (error) => {
      toast({
        title: 'Error saving strokes gained',
        description: error.message || 'There was an error saving your strokes gained data.',
        variant: 'destructive',
      });
    }
  });
  
  return {
    strokesGained: userStrokesGained,
    allStrokesGained: strokesGained,
    isLoading,
    isError,
    error,
    createStrokesGained,
    timePeriod,
    setTimePeriod,
  };
}

// Hook for accessing strokes gained data for a specific round
export function useRoundStrokesGained(roundId: number) {
  const { toast } = useToast();
  
  // Get strokes gained data for a specific round
  const {
    data: strokesGained,
    isLoading,
    isError,
    error
  } = useQuery<StrokesGained>({
    queryKey: ['/api/strokes-gained/round', roundId],
    enabled: !!roundId,
  });
  
  // Create/update strokes gained for a round
  const updateRoundStrokesGained = useMutation({
    mutationFn: async (data: InsertStrokesGained) => {
      try {
        const response = await apiRequest('POST', `/api/strokes-gained`, data);
        
        // Check if the response is ok before trying to parse JSON
        if (!response.ok) {
          return { error: `Server responded with ${response.status}` };
        }
        
        // Check if the response is empty
        const text = await response.text();
        if (!text || text.trim() === '') {
          return { success: true };
        }
        
        try {
          const json = JSON.parse(text);
          return json;
        } catch (e) {
          console.error("JSON parse error:", e, "Response text:", text);
          return { success: true };
        }
      } catch (error) {
        console.error("API request error:", error);
        throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/strokes-gained/round', roundId] });
      queryClient.invalidateQueries({ queryKey: ['/api/strokes-gained'] });
      toast({
        title: 'Strokes gained updated',
        description: 'Round strokes gained data has been saved successfully.',
      });
    },
    onError: (error) => {
      // Log the error but don't show toast to user, allowing navigation to continue
      console.error('Error saving strokes gained:', error);
    }
  });
  
  return {
    strokesGained,
    isLoading,
    isError,
    error,
    updateRoundStrokesGained,
  };
}