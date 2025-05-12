import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

// Format date as Month DD, YYYY
export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });
}

// Format relative score (e.g., +2, -1, E)
export function formatRelativeScore(score: number | null): string {
  if (score === null) return 'N/A';
  if (score === 0) return 'E';
  return score > 0 ? `+${score}` : `${score}`;
}

// Calculate fairway hit percentage
export function calculateFairwayPercentage(fairwaysHit: number, fairwaysTotal: number): number {
  if (fairwaysTotal === 0) return 0;
  return Math.round((fairwaysHit / fairwaysTotal) * 100);
}

// Calculate greens in regulation percentage
export function calculateGIRPercentage(gir: number, holes: number): number {
  if (holes === 0) return 0;
  return Math.round((gir / holes) * 100);
}

// Calculate average putts per hole
export function calculateAveragePutts(totalPutts: number, holes: number): number {
  if (holes === 0) return 0;
  return parseFloat((totalPutts / holes).toFixed(1));
}

// Convert yards to meters
export function yardsToMeters(yards: number): number {
  return Math.round(yards * 0.9144);
}

// Convert meters to yards
export function metersToYards(meters: number): number {
  return Math.round(meters / 0.9144);
}

// Convert feet to meters
export function feetToMeters(feet: number): number {
  return parseFloat((feet * 0.3048).toFixed(1));
}

// Format distance with units
export function formatDistance(distance: number, unit: 'yards' | 'meters'): string {
  if (unit === 'meters') {
    return `${yardsToMeters(distance)} m`;
  }
  return `${distance} yds`;
}

// Format putt distance with units
export function formatPuttDistance(distance: number, unit: 'feet' | 'meters'): string {
  if (unit === 'meters') {
    return `${feetToMeters(distance)} m`;
  }
  return `${distance} ft`;
}

// Get club type icon (for display purposes)
export function getClubTypeIcon(type: string): string {
  switch (type.toLowerCase()) {
    case 'driver':
      return 'golf_course';
    case 'wood':
      return 'sports_golf';
    case 'iron':
      return 'iron';
    case 'wedge':
      return 'golf_course';
    case 'putter':
      return 'center_focus_strong';
    default:
      return 'sports_golf';
  }
}

// Get weather icon
export function getWeatherIcon(weather: string): string {
  switch (weather.toLowerCase()) {
    case 'sunny':
      return 'wb_sunny';
    case 'cloudy':
      return 'cloud';
    case 'rainy':
      return 'water_drop';
    case 'windy':
      return 'air';
    default:
      return 'wb_sunny';
  }
}

// Calculate strokes gained color
export function getStrokesGainedColor(value: number | null): string {
  if (value === null) return 'text-neutral-medium';
  return value >= 0 ? 'text-success' : 'text-error';
}

// Calculate percentage for progress bars
export function calculatePercentage(value: number, max: number): number {
  if (max === 0) return 0;
  return Math.min(100, Math.max(0, (value / max) * 100));
}

// Calculate normalized percentage (for displaying relative values)
export function normalizePercentage(value: number, min: number, max: number): number {
  if (max === min) return 50;
  return 50 + ((value - ((min + max) / 2)) / (max - min)) * 50;
}

// Parse date string to ISO format
export function parseDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toISOString().split('T')[0];
}

// Generate stats for a time period
export function filterByTimePeriod<T>(items: T[], dateField: keyof T, days: number): T[] {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);
  
  return items.filter(item => {
    const itemDate = new Date(item[dateField] as string);
    return itemDate >= cutoffDate;
  });
}
