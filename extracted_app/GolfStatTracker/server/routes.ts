import express, { Request, Response } from "express";
import { storage } from "./storage";
import { insertHoleSchema, insertRoundSchema, insertClubSchema, insertStrokesGainedSchema, insertCourseSchema } from "@shared/schema";
import { log } from "./vite";
import fetch from "node-fetch";
import { googleAuthRouter } from "./routes/google-auth";

// Golf Course API configuration
const GOLF_COURSE_API_URL = 'https://api.golfcourseapi.com/v1';
const GOLF_COURSE_API_KEY = process.env.GOLF_COURSE_API_KEY || '';

// Headers for Golf Course API requests
function getGolfApiHeaders() {
  return {
    'Authorization': `Key ${GOLF_COURSE_API_KEY}`,
    'Content-Type': 'application/json',
  };
}

const api = express.Router();

// Error handling middleware
const asyncHandler = (fn: any) => (req: Request, res: Response, next: any) =>
  Promise.resolve(fn(req, res, next)).catch(err => {
    console.error(err);
    res.status(500).json({ message: err.message });
  });

// User endpoints
api.get('/user/:id', asyncHandler(async (req: Request, res: Response) => {
  const userId = parseInt(req.params.id);
  const user = await storage.getUser(userId);
  if (!user) {
    return res.status(404).json({ message: 'User not found' });
  }
  res.json(user);
}));

// Club endpoints
api.get('/clubs', asyncHandler(async (req: Request, res: Response) => {
  const userId = 1; // Hardcoded for now
  const clubs = await storage.getClubsByUserId(userId);
  res.json(clubs);
}));

api.post('/clubs', asyncHandler(async (req: Request, res: Response) => {
  const clubData = insertClubSchema.parse(req.body);
  const club = await storage.createClub(clubData);
  res.status(201).json(club);
}));

api.put('/clubs/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  const clubData = req.body;
  const club = await storage.updateClub(id, clubData);
  res.json(club);
}));

api.delete('/clubs/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  await storage.deleteClub(id);
  res.status(204).send();
}));

// Course endpoints
api.get('/courses', asyncHandler(async (req: Request, res: Response) => {
  try {
    const name = req.query.name as string;
    if (name) {
      const course = await storage.getCourseByName(name);
      return res.json(course || null);
    } else {
      return res.status(400).json({ message: 'Course name is required' });
    }
  } catch (error) {
    console.error('Error fetching course:', error);
    res.status(500).json({ message: 'Error fetching course' });
  }
}));

api.post('/courses', asyncHandler(async (req: Request, res: Response) => {
  try {
    const courseData = insertCourseSchema.parse(req.body);
    const course = await storage.createCourse(courseData);
    res.status(201).json(course);
  } catch (error) {
    console.error('Error creating course:', error);
    res.status(500).json({ message: 'Error creating course' });
  }
}));

// Round endpoints
api.get('/rounds', asyncHandler(async (req: Request, res: Response) => {
  try {
    const userId = 1; // Hardcoded for now
    const rounds = await storage.getRoundsByUserId(userId);
    res.json(rounds);
  } catch (error) {
    console.error('Error getting rounds:', error);
    res.status(500).json({ message: 'Error getting rounds' });
  }
}));

api.get('/rounds/:id', asyncHandler(async (req: Request, res: Response) => {
  const roundId = parseInt(req.params.id);
  const round = await storage.getRound(roundId);
  if (!round) {
    return res.status(404).json({ message: 'Round not found' });
  }
  res.json(round);
}));

api.post('/rounds', asyncHandler(async (req: Request, res: Response) => {
  const roundData = insertRoundSchema.parse(req.body);
  const round = await storage.createRound(roundData);
  res.status(201).json(round);
}));

api.put('/rounds/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  const roundData = req.body;
  const round = await storage.updateRound(id, roundData);
  res.json(round);
}));

api.delete('/rounds/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  await storage.deleteRound(id);
  res.status(204).send();
}));

// Hole endpoints
api.get('/rounds/:roundId/holes', asyncHandler(async (req: Request, res: Response) => {
  const roundId = parseInt(req.params.roundId);
  const holes = await storage.getHolesByRoundId(roundId);
  res.json(holes);
}));

api.post('/rounds/:roundId/holes', asyncHandler(async (req: Request, res: Response) => {
  const roundId = parseInt(req.params.roundId);
  const holeData = { ...req.body, roundId };
  const validatedData = insertHoleSchema.parse(holeData);
  const hole = await storage.createHole(validatedData);
  res.status(201).json(hole);
}));

api.put('/holes/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  const holeData = req.body;
  const hole = await storage.updateHole(id, holeData);
  res.json(hole);
}));

// Shot endpoints
api.get('/holes/:holeId/shots', asyncHandler(async (req: Request, res: Response) => {
  const holeId = parseInt(req.params.holeId);
  const shots = await storage.getShotsByHoleId(holeId);
  res.json(shots);
}));

api.post('/holes/:holeId/shots', asyncHandler(async (req: Request, res: Response) => {
  const holeId = parseInt(req.params.holeId);
  const shotData = { ...req.body, holeId };
  const shot = await storage.createShot(shotData);
  res.status(201).json(shot);
}));

api.put('/shots/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  const shotData = req.body;
  const shot = await storage.updateShot(id, shotData);
  res.json(shot);
}));

// Strokes gained endpoints
api.get('/strokes-gained/user/:userId', asyncHandler(async (req: Request, res: Response) => {
  const userId = parseInt(req.params.userId);
  const strokesGained = await storage.getStrokesGainedByUserId(userId);
  res.json(strokesGained);
}));

api.get('/strokes-gained/round/:roundId', asyncHandler(async (req: Request, res: Response) => {
  const roundId = parseInt(req.params.roundId);
  const strokesGained = await storage.getStrokesGainedByRoundId(roundId);
  res.json(strokesGained);
}));

api.post('/strokes-gained', asyncHandler(async (req: Request, res: Response) => {
  const sgData = insertStrokesGainedSchema.parse(req.body);
  const strokesGained = await storage.createStrokesGained(sgData);
  res.status(201).json(strokesGained);
}));

api.put('/strokes-gained/:id', asyncHandler(async (req: Request, res: Response) => {
  const id = parseInt(req.params.id);
  const sgData = req.body;
  const strokesGained = await storage.updateStrokesGained(id, sgData);
  res.json(strokesGained);
}));

// Bulk create holes for a round
api.post('/rounds/:roundId/holes/bulk', asyncHandler(async (req: Request, res: Response) => {
  try {
    const roundId = parseInt(req.params.roundId);
    const holesData = req.body;
    
    if (!Array.isArray(holesData)) {
      return res.status(400).json({ message: 'Expected an array of holes' });
    }

    const holes = [];
    for (const holeData of holesData) {
      const data = { ...holeData, roundId };
      const hole = await storage.createHole(data);
      holes.push(hole);
    }
    
    res.status(201).json(holes);
  } catch (error) {
    console.error('Error creating holes in bulk:', error);
    res.status(500).json({ message: 'Error creating holes' });
  }
}));

// Golf Course API proxy endpoints
api.get('/golf-api/search', asyncHandler(async (req: Request, res: Response) => {
  try {
    const query = req.query.search_query as string;
    
    if (!query) {
      return res.status(400).json({ message: 'Search query is required' });
    }
    
    if (!GOLF_COURSE_API_KEY) {
      console.warn('No Golf Course API key configured');
      return res.status(500).json({ 
        message: 'Golf Course API key not configured',
        courses: [] 
      });
    }
    
    console.log(`Searching golf courses with query: ${query}`);
    const apiUrl = `${GOLF_COURSE_API_URL}/search?search_query=${encodeURIComponent(query)}`;
    console.log(`API request URL: ${apiUrl}`);
    console.log(`API headers:`, getGolfApiHeaders());
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: getGolfApiHeaders()
    });
    
    if (!response.ok) {
      console.error(`API responded with status: ${response.status}`);
      const errorText = await response.text();
      console.error(`Error text: ${errorText}`);
      return res.status(response.status).json({ 
        message: `Golf course search failed: ${response.statusText}`,
        courses: [] 
      });
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Error searching for golf courses:', error);
    res.status(500).json({ 
      message: 'Error searching for golf courses',
      courses: [] 
    });
  }
}));

api.get('/golf-api/courses/:id', asyncHandler(async (req: Request, res: Response) => {
  try {
    const courseId = req.params.id;
    
    if (!GOLF_COURSE_API_KEY) {
      console.warn('No Golf Course API key configured');
      return res.status(500).json({ message: 'Golf Course API key not configured' });
    }
    
    console.log(`Fetching golf course with ID: ${courseId}`);
    const response = await fetch(`${GOLF_COURSE_API_URL}/courses/${courseId}`, {
      method: 'GET',
      headers: getGolfApiHeaders()
    });
    
    if (!response.ok) {
      console.error(`API responded with status: ${response.status}`);
      const errorText = await response.text();
      console.error(`Error text: ${errorText}`);
      return res.status(response.status).json({ 
        message: `Failed to get golf course details: ${response.statusText}`
      });
    }
    
    const data = await response.json();
    res.json(data);
    
  } catch (error) {
    console.error('Error getting golf course details:', error);
    res.status(500).json({ message: 'Error getting golf course details' });
  }
}));

// Register Google sheets routes
api.use('/google', googleAuthRouter);

export { api };