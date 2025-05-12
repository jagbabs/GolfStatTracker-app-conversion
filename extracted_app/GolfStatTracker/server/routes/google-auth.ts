import express, { Request, Response } from 'express';
import { 
  getAuthUrl, 
  getTokens, 
  exportAllData, 
  updateCredentials 
} from '../services/google-sheets';
import { storage } from '../storage';

export const googleAuthRouter = express.Router();

// Store tokens temporarily in memory (in production, this should be in a database)
const userTokens: Record<number, any> = {};

// Update Google OAuth credentials
googleAuthRouter.post('/credentials', async (req: Request, res: Response) => {
  try {
    const { clientId, clientSecret, redirectUri } = req.body;
    
    if (!clientId || !clientSecret) {
      return res.status(400).json({ message: 'Client ID and Client Secret are required' });
    }
    
    updateCredentials(clientId, clientSecret, redirectUri);
    
    res.status(200).json({ message: 'Credentials updated successfully' });
  } catch (error) {
    console.error('Error updating credentials:', error);
    res.status(500).json({ message: 'Failed to update credentials' });
  }
});

// Get auth URL for Google OAuth
googleAuthRouter.get('/auth-url', (req: Request, res: Response) => {
  try {
    const authUrl = getAuthUrl();
    res.json({ url: authUrl });
  } catch (error) {
    console.error('Error generating auth URL:', error);
    res.status(500).json({ message: 'Failed to generate auth URL' });
  }
});

// Handle OAuth callback
googleAuthRouter.get('/callback', async (req: Request, res: Response) => {
  try {
    const { code, state } = req.query;
    const userId = parseInt(state as string);
    
    if (!code) {
      return res.status(400).send('Authorization code is missing');
    }
    
    // Exchange code for tokens
    const tokens = await getTokens(code as string);
    
    // Store tokens for this user
    userTokens[userId] = tokens;
    
    // Redirect to frontend with success message
    res.redirect('/export-success');
  } catch (error) {
    console.error('Error in OAuth callback:', error);
    res.status(500).send('Authentication failed');
  }
});

// Export user data to Google Sheets
googleAuthRouter.post('/export/:userId', async (req: Request, res: Response) => {
  try {
    const userId = parseInt(req.params.userId);
    
    // Check if we have tokens for this user
    if (!userTokens[userId]) {
      return res.status(401).json({ 
        message: 'User not authenticated with Google',
        needsAuth: true,
        authUrl: getAuthUrl()
      });
    }
    
    // Fetch all user data
    const rounds = await storage.getRoundsByUserId(userId);
    
    // Fetch holes for all rounds
    let allHoles: any[] = [];
    for (const round of rounds) {
      const holes = await storage.getHolesByRoundId(round.id);
      allHoles = [...allHoles, ...holes];
    }
    
    // Fetch shots for all holes
    let allShots: any[] = [];
    for (const hole of allHoles) {
      const shots = await storage.getShotsByHoleId(hole.id);
      allShots = [...allShots, ...shots];
    }
    
    // Fetch clubs
    const clubs = await storage.getClubsByUserId(userId);
    
    // Fetch strokes gained data
    const strokesGained = await storage.getStrokesGainedByUserId(userId);
    
    // Export all data to Google Sheets
    const spreadsheetUrl = await exportAllData(
      userTokens[userId],
      userId,
      rounds,
      allHoles,
      allShots,
      clubs,
      strokesGained
    );
    
    res.json({ 
      message: 'Data exported successfully',
      url: spreadsheetUrl
    });
  } catch (error) {
    console.error('Error exporting data:', error);
    res.status(500).json({ message: 'Failed to export data' });
  }
});

// Check if user is authenticated with Google
googleAuthRouter.get('/status/:userId', (req: Request, res: Response) => {
  const userId = parseInt(req.params.userId);
  const isAuthenticated = !!userTokens[userId];
  
  res.json({
    isAuthenticated,
    authUrl: isAuthenticated ? null : getAuthUrl()
  });
});

// Logout from Google (remove tokens)
googleAuthRouter.post('/logout/:userId', (req: Request, res: Response) => {
  const userId = parseInt(req.params.userId);
  
  if (userTokens[userId]) {
    delete userTokens[userId];
    res.json({ message: 'Logged out successfully' });
  } else {
    res.status(404).json({ message: 'User not found or already logged out' });
  }
});