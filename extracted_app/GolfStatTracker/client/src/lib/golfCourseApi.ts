import { GolfCourse, SearchResult, TeeBox, Hole } from '../types/golfCourseApi';

// Using our server proxy instead of calling the Golf Course API directly
const API_PROXY_URL = '/api/golf-api';

/**
 * Search for golf courses by name
 * @param query The search term
 * @returns A promise with search results
 */
export async function searchGolfCourses(query: string): Promise<SearchResult> {
  try {
    const response = await fetch(`${API_PROXY_URL}/search?search_query=${encodeURIComponent(query)}`, {
      method: 'GET',
    });

    if (!response.ok) {
      let errorMessage = `Golf course search failed: ${response.statusText}`;
      try {
        const errorData = await response.json();
        console.error('API error:', errorData);
        if (errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // If response is not JSON, just use the status text
      }
      throw new Error(errorMessage);
    }

    const data = await response.json();
    
    // Log the search results for debugging
    if (data.courses && Array.isArray(data.courses)) {
      console.log(`API returned ${data.courses.length} courses before filtering`);
      
      // Don't filter out US courses for now (enabling all results)
      // Just log what countries are available
      const countries = new Set();
      data.courses.forEach((course: GolfCourse) => {
        if (course.location && course.location.country) {
          countries.add(course.location.country);
        }
      });
      console.log('Available countries:', Array.from(countries));
    }
    
    return data;
  } catch (error) {
    console.error('Error searching for golf courses:', error);
    return { courses: [] };
  }
}

/**
 * Get detailed information about a specific golf course
 * @param id The golf course ID
 * @returns A promise with the course details
 */
export async function getGolfCourseById(id: number): Promise<GolfCourse> {
  console.log(`Fetching detailed info for course ID: ${id}`);
  
  try {
    const response = await fetch(`${API_PROXY_URL}/courses/${id}`, {
      method: 'GET',
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
      }
    });

    if (!response.ok) {
      let errorMessage = `Failed to get golf course details: ${response.statusText}`;
      try {
        const errorData = await response.json();
        console.error('API error:', errorData);
        if (errorData.message) {
          errorMessage = errorData.message;
        }
      } catch (e) {
        // If response is not JSON, just use the status text
      }
      throw new Error(errorMessage);
    }

    const courseData = await response.json();
    
    // Log the course data for debugging
    console.log(`Retrieved data for ${courseData.club_name || 'Unknown Course'}`);
    console.log(`Course has tee boxes:`, !!courseData.tees);
    
    // Normalize the course data to ensure it has all required fields
    const normalizedCourse: GolfCourse = {
      id: courseData.id,
      club_name: courseData.club_name || 'Unknown Club',
      course_name: courseData.course_name || 'Main Course',
      location: courseData.location || {},
      holes: courseData.holes || [],
      tees: courseData.tees || { male: [], female: [] }
    };
    
    return normalizedCourse;
  } catch (error) {
    console.error('Error getting golf course details:', error);
    // Return a default course with the requested ID as a fallback
    throw new Error(`Could not load course details: ${error}`);
  }
}

/**
 * Get a list of tee boxes available for a course
 * @param course The golf course object
 * @returns A formatted list of tee boxes with gender indication
 */
export function getFormattedTeeBoxes(course: GolfCourse): { label: string; value: string; data: TeeBox }[] {
  const teeBoxes: { label: string; value: string; data: TeeBox }[] = [];
  
  console.log('Formatting tee boxes for course:', course.club_name);

  // Log the raw tees object to debug
  console.log('Raw tees data:', JSON.stringify(course.tees || {}));

  try {
    // Add male tee boxes
    if (course.tees?.male && Array.isArray(course.tees.male)) {
      console.log(`Found ${course.tees.male.length} men's tee boxes`);
      course.tees.male.forEach((tee: TeeBox, index) => {
        // Validate tee box data
        if (!tee.tee_name) {
          tee.tee_name = `Men's Tee ${index + 1}`;
        }
        
        teeBoxes.push({
          label: `${tee.tee_name} (Men)`,
          value: `male-${tee.tee_name}`,
          data: tee
        });
      });
    } else {
      console.log('No men\'s tee boxes found or data is malformed');
    }

    // Add female tee boxes
    if (course.tees?.female && Array.isArray(course.tees.female)) {
      console.log(`Found ${course.tees.female.length} women's tee boxes`);
      course.tees.female.forEach((tee: TeeBox, index) => {
        // Validate tee box data
        if (!tee.tee_name) {
          tee.tee_name = `Women's Tee ${index + 1}`;
        }
        
        teeBoxes.push({
          label: `${tee.tee_name} (Women)`,
          value: `female-${tee.tee_name}`,
          data: tee
        });
      });
    } else {
      console.log('No women\'s tee boxes found or data is malformed');
    }
    
    // If no tee boxes were found, create a default one
    if (teeBoxes.length === 0 && course.holes && Array.isArray(course.holes) && course.holes.length > 0) {
      console.log('No tee boxes found, creating a default tee box from hole data');
      
      // Create a default tee box using the course holes
      const defaultTeeBox: TeeBox = {
        tee_name: 'Default',
        tee_color: 'White',
        tee_gender: 'male',
        par_total: course.holes.reduce((sum: number, hole: Hole) => sum + (hole.par || 4), 0),
        total_yards: course.holes.reduce((sum: number, hole: Hole) => sum + (hole.yardage || 0), 0),
        course_rating: 72,
        slope_rating: 113,
        number_of_holes: course.holes.length,
        holes: course.holes
      };
      
      teeBoxes.push({
        label: 'Default Tees (Men)',
        value: 'male-Default',
        data: defaultTeeBox
      });
    }
  } catch (error) {
    console.error('Error formatting tee boxes:', error);
  }

  console.log(`Returning ${teeBoxes.length} formatted tee boxes`);
  return teeBoxes;
}

/**
 * Convert API course and tee box data to local course data format
 */
export function convertToLocalCourse(course: GolfCourse, selectedTeeBox: TeeBox) {
  return {
    id: course.id,
    name: `${course.club_name} - ${course.course_name}`,
    city: course.location?.city || null,
    state: course.location?.state || null,
    country: course.location?.country || null,
    numHoles: selectedTeeBox.number_of_holes || 18,
    holeDetails: selectedTeeBox.holes || []
  };
}

/**
 * Format hole details for use in the application
 */
export function formatHoleDetails(holes: Hole[], courseId: number, roundId: number): any[] {
  return holes.map((hole, index) => ({
    roundId,
    holeNumber: index + 1,
    par: hole.par,
    distance: hole.yardage,
    score: null,
    fairwayHit: null,
    greenInRegulation: null,
    numPutts: null,
    numPenalties: null,
    upAndDown: null,
    sandSave: null,
    strokesGained: null
  }));
}