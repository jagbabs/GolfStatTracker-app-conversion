// Types for the Golf Course API

export interface GolfCourse {
  id: number;
  club_name: string;
  course_name: string;
  location?: {
    address?: string;
    city?: string;
    state?: string;
    country?: string;
    latitude?: number;
    longitude?: number;
  };
  tees?: {
    female?: TeeBox[];
    male?: TeeBox[];
  };
  holes?: Hole[]; // Some API responses include holes at the course level
  tee_gender?: string; // For fallback data
}

export interface SearchResult {
  courses: GolfCourse[];
}

export interface TeeBox {
  tee_name: string;
  tee_color?: string; // Some tee boxes include color
  tee_gender?: string; // Some tee boxes include gender
  course_rating: number;
  slope_rating: number;
  bogey_rating?: number;
  total_yards: number;
  total_meters?: number;
  number_of_holes: number;
  par_total: number;
  front_course_rating?: number;
  front_slope_rating?: number;
  front_bogey_rating?: number;
  back_course_rating?: number;
  back_slope_rating?: number;
  back_bogey_rating?: number;
  holes: Hole[];
}

export interface Hole {
  par: number;
  yardage: number;
  handicap: number;
}