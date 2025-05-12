import { useState, useEffect } from 'react';
import { useQuery, useMutation } from '@tanstack/react-query';
import { apiRequest } from '@/lib/queryClient';
import { queryClient } from '@/lib/queryClient';
import { Club } from '@shared/schema';

export function useClubs() {
  const {
    data: clubs = [],
    isLoading,
    isError,
    error
  } = useQuery<Club[]>({
    queryKey: ['/api/clubs'],
  });

  // Create new club
  const createClub = useMutation({
    mutationFn: async (club: Omit<Club, 'id'>) => {
      const response = await apiRequest('POST', '/api/clubs', club);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/clubs'] });
    },
  });

  // Update club
  const updateClub = useMutation({
    mutationFn: async (club: Club) => {
      const response = await apiRequest('PUT', `/api/clubs/${club.id}`, club);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/clubs'] });
    },
  });

  // Delete club
  const deleteClub = useMutation({
    mutationFn: async (clubId: number) => {
      const response = await apiRequest('DELETE', `/api/clubs/${clubId}`);
      return response.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['/api/clubs'] });
    },
  });

  // Sort clubs by type and distance
  const sortedClubs = [...clubs].sort((a, b) => {
    // Order by type: driver, woods, irons, wedges, putter
    const typeOrder = {
      driver: 1,
      wood: 2,
      iron: 3,
      wedge: 4,
      putter: 5,
    };
    
    const typeA = a.type.toLowerCase() as keyof typeof typeOrder;
    const typeB = b.type.toLowerCase() as keyof typeof typeOrder;
    
    if (typeOrder[typeA] !== typeOrder[typeB]) {
      return typeOrder[typeA] - typeOrder[typeB];
    }
    
    // Within the same type, sort by distance (descending)
    if (a.distance && b.distance) {
      return b.distance - a.distance;
    }
    
    // If distances are not available, sort by name
    return a.name.localeCompare(b.name);
  });

  // Get club by ID
  const getClubById = (clubId: number): Club | undefined => {
    return clubs.find(club => club.id === clubId);
  };

  // Get club by name
  const getClubByName = (clubName: string): Club | undefined => {
    return clubs.find(club => club.name.toLowerCase() === clubName.toLowerCase());
  };

  return {
    clubs: sortedClubs,
    isLoading,
    isError,
    error,
    createClub,
    updateClub,
    deleteClub,
    getClubById,
    getClubByName
  };
}
