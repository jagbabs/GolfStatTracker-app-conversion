import { useState } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { queryClient } from '@/lib/queryClient';
import { Round, Hole, Shot, InsertRound, InsertHole, InsertShot } from '@shared/schema';
import { useToast } from '@/hooks/use-toast';

export function useRounds() {
  const { toast } = useToast();
  
  // Get all rounds
  const {
    data: rounds = [],
    isLoading,
    isError,
    error
  } = useQuery<Round[]>({
    queryKey: ['/api/rounds'],
  });
  
  // Create a new round
  const createRound = useMutation({
    mutationFn: async (round: InsertRound) => {
      const response = await apiRequest('POST', '/api/rounds', round);
      return response.json();
    },
    onSuccess: (data) => {
      queryClient.invalidateQueries({ queryKey: ['/api/rounds'] });
      toast({
        title: 'Round created',
        description: 'Your new round has been created successfully.',
      });
      return data;
    },
    onError: (error) => {
      toast({
        title: 'Error creating round',
        description: error.message || 'There was an error creating your round.',
        variant: 'destructive',
      });
    }
  });
  
  // Update a round
  const updateRound = useMutation({
    mutationFn: async (round: Round) => {
      const response = await apiRequest('PUT', `/api/rounds/${round.id}`, round);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/rounds'] });
      toast({
        title: 'Round updated',
        description: 'Your round has been updated successfully.',
      });
    },
    onError: (error) => {
      toast({
        title: 'Error updating round',
        description: error.message || 'There was an error updating your round.',
        variant: 'destructive',
      });
    }
  });
  
  // Delete a round
  const deleteRound = useMutation({
    mutationFn: async (roundId: number) => {
      const response = await apiRequest('DELETE', `/api/rounds/${roundId}`);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/rounds'] });
      toast({
        title: 'Round deleted',
        description: 'Your round has been deleted successfully.',
      });
    },
    onError: (error) => {
      toast({
        title: 'Error deleting round',
        description: error.message || 'There was an error deleting your round.',
        variant: 'destructive',
      });
    }
  });
  
  return {
    rounds,
    isLoading,
    isError,
    error,
    createRound,
    updateRound,
    deleteRound,
  };
}

export function useRound(roundId: number) {
  const { toast } = useToast();
  
  // Get specific round
  const {
    data: round,
    isLoading: isRoundLoading,
    isError: isRoundError,
    error: roundError
  } = useQuery<Round>({
    queryKey: [`/api/rounds/${roundId}`],
    enabled: !!roundId,
  });
  
  // Get holes for the round
  const {
    data: holes = [],
    isLoading: isHolesLoading,
    isError: isHolesError,
    error: holesError
  } = useQuery<Hole[]>({
    queryKey: [`/api/rounds/${roundId}/holes`],
    enabled: !!roundId,
  });
  
  // Create a new hole
  const createHole = useMutation({
    mutationFn: async (hole: InsertHole) => {
      const response = await apiRequest('POST', `/api/rounds/${roundId}/holes`, hole);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/rounds/${roundId}/holes`] });
    },
    onError: (error) => {
      toast({
        title: 'Error creating hole',
        description: error.message || 'There was an error saving the hole data.',
        variant: 'destructive',
      });
    }
  });
  
  // Update a hole
  const updateHole = useMutation({
    mutationFn: async (hole: Hole) => {
      const response = await apiRequest('PUT', `/api/holes/${hole.id}`, hole);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/rounds/${roundId}/holes`] });
    },
    onError: (error) => {
      toast({
        title: 'Error updating hole',
        description: error.message || 'There was an error updating the hole data.',
        variant: 'destructive',
      });
    }
  });
  
  // Get shots for a hole
  const getShots = (holeId: number) => {
    return useQuery<Shot[]>({
      queryKey: [`/api/holes/${holeId}/shots`],
      enabled: !!holeId,
    });
  };
  
  // Create a new shot
  const createShot = useMutation({
    mutationFn: async ({ holeId, shot }: { holeId: number; shot: InsertShot }) => {
      const response = await apiRequest('POST', `/api/holes/${holeId}/shots`, shot);
      return response.json();
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [`/api/holes/${variables.holeId}/shots`] });
    },
    onError: (error) => {
      toast({
        title: 'Error saving shot',
        description: error.message || 'There was an error saving the shot data.',
        variant: 'destructive',
      });
    }
  });
  
  // Update a shot
  const updateShot = useMutation({
    mutationFn: async (shot: Shot) => {
      const response = await apiRequest('PUT', `/api/shots/${shot.id}`, shot);
      return response.json();
    },
    onSuccess: (_, variables) => {
      queryClient.invalidateQueries({ queryKey: [`/api/holes/${variables.holeId}/shots`] });
    },
    onError: (error) => {
      toast({
        title: 'Error updating shot',
        description: error.message || 'There was an error updating the shot data.',
        variant: 'destructive',
      });
    }
  });
  
  // Update the round
  const updateRound = useMutation({
    mutationFn: async (round: Round) => {
      const response = await apiRequest('PUT', `/api/rounds/${round.id}`, round);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/rounds/${roundId}`] });
      queryClient.invalidateQueries({ queryKey: ['/api/rounds'] });
      toast({
        title: 'Round updated',
        description: 'Your round has been updated successfully.',
      });
    },
    onError: (error) => {
      toast({
        title: 'Error updating round',
        description: error.message || 'There was an error updating your round.',
        variant: 'destructive',
      });
    }
  });
  
  return {
    round,
    holes,
    isLoading: isRoundLoading || isHolesLoading,
    isError: isRoundError || isHolesError,
    error: roundError || holesError,
    createHole,
    updateHole,
    updateRound,
    getShots,
    createShot,
    updateShot,
  };
}
