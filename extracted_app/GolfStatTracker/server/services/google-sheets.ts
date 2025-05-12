import { google, sheets_v4 } from 'googleapis';
import { OAuth2Client } from 'google-auth-library';
import { Round, Hole, Shot, StrokesGained, Club } from '@shared/schema';

// Define scopes needed for the application
const SCOPES = [
  'https://www.googleapis.com/auth/spreadsheets',
  'https://www.googleapis.com/auth/drive.file'
];

// Credentials placeholder - these should be obtained through environment variables
// We'll add a proper way to request these secrets from the user
let credentials = {
  client_id: process.env.GOOGLE_CLIENT_ID || '',
  client_secret: process.env.GOOGLE_CLIENT_SECRET || '',
  redirect_uri: process.env.GOOGLE_REDIRECT_URI || 'http://localhost:5000/auth/google/callback'
};

// Create an OAuth2 client
const createOAuth2Client = (): OAuth2Client => {
  return new google.auth.OAuth2(
    credentials.client_id,
    credentials.client_secret,
    credentials.redirect_uri
  );
};

// Get the URL for user authorization
export const getAuthUrl = (): string => {
  const oauth2Client = createOAuth2Client();
  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
    prompt: 'consent'
  });
};

// Exchange authorization code for tokens
export const getTokens = async (code: string) => {
  const oauth2Client = createOAuth2Client();
  const { tokens } = await oauth2Client.getToken(code);
  return tokens;
};

// Initialize a sheets client with auth tokens
export const createSheetsClient = (tokens: any): sheets_v4.Sheets => {
  const oauth2Client = createOAuth2Client();
  oauth2Client.setCredentials(tokens);
  return google.sheets({ version: 'v4', auth: oauth2Client });
};

// Create a new spreadsheet
export const createSpreadsheet = async (sheets: sheets_v4.Sheets, title: string): Promise<string> => {
  try {
    const response = await sheets.spreadsheets.create({
      requestBody: {
        properties: {
          title
        },
        sheets: [
          { properties: { title: 'Rounds' } },
          { properties: { title: 'Holes' } },
          { properties: { title: 'Shots' } },
          { properties: { title: 'Clubs' } },
          { properties: { title: 'StrokesGained' } }
        ]
      }
    });
    
    return response.data.spreadsheetId || '';
  } catch (error) {
    console.error('Error creating spreadsheet:', error);
    throw error;
  }
};

// Format export headers for different data types
const getHeadersForDataType = (dataType: string): string[] => {
  switch (dataType) {
    case 'Rounds':
      return ['ID', 'User ID', 'Date', 'Course', 'Score', 'Notes', 'Course ID', 'Tee Box', 'Temperature', 'Weather', 'Wind Speed', 'Wind Direction', 'Created At'];
    case 'Holes':
      return ['ID', 'Round ID', 'Hole Number', 'Par', 'Distance', 'Score', 'Fairway Hit', 'Green In Regulation', 'Num Putts', 'Num Penalties', 'Up And Down', 'Sand Save', 'Strokes Gained'];
    case 'Shots':
      return ['ID', 'Hole ID', 'Shot Number', 'Club ID', 'Type', 'Distance To Target', 'Outcome', 'Direction'];
    case 'Clubs':
      return ['ID', 'User ID', 'Name', 'Type', 'Brand', 'Model', 'Loft', 'Created At'];
    case 'StrokesGained':
      return ['ID', 'User ID', 'Date', 'Off Tee', 'Approach', 'Around Green', 'Putting', 'Total', 'Round ID'];
    default:
      return [];
  }
};

// Helper function to convert objects to row values
const objectToRowValues = (obj: any, headers: string[]): any[] => {
  return headers.map(header => {
    const key = header.toLowerCase().replace(/\s+/g, '');
    return obj[key] !== undefined ? obj[key] : '';
  });
};

// Export rounds data to a sheet
export const exportRoundsToSheet = async (
  sheets: sheets_v4.Sheets, 
  spreadsheetId: string, 
  rounds: Round[]
): Promise<void> => {
  try {
    const headers = getHeadersForDataType('Rounds');
    const values = [headers];
    
    rounds.forEach(round => {
      values.push(objectToRowValues(round, headers));
    });
    
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Rounds!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values
      }
    });
  } catch (error) {
    console.error('Error exporting rounds:', error);
    throw error;
  }
};

// Export holes data to a sheet
export const exportHolesToSheet = async (
  sheets: sheets_v4.Sheets, 
  spreadsheetId: string, 
  holes: Hole[]
): Promise<void> => {
  try {
    const headers = getHeadersForDataType('Holes');
    const values = [headers];
    
    holes.forEach(hole => {
      values.push(objectToRowValues(hole, headers));
    });
    
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Holes!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values
      }
    });
  } catch (error) {
    console.error('Error exporting holes:', error);
    throw error;
  }
};

// Export shots data to a sheet
export const exportShotsToSheet = async (
  sheets: sheets_v4.Sheets, 
  spreadsheetId: string, 
  shots: Shot[]
): Promise<void> => {
  try {
    const headers = getHeadersForDataType('Shots');
    const values = [headers];
    
    shots.forEach(shot => {
      values.push(objectToRowValues(shot, headers));
    });
    
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Shots!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values
      }
    });
  } catch (error) {
    console.error('Error exporting shots:', error);
    throw error;
  }
};

// Export clubs data to a sheet
export const exportClubsToSheet = async (
  sheets: sheets_v4.Sheets, 
  spreadsheetId: string, 
  clubs: Club[]
): Promise<void> => {
  try {
    const headers = getHeadersForDataType('Clubs');
    const values = [headers];
    
    clubs.forEach(club => {
      values.push(objectToRowValues(club, headers));
    });
    
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'Clubs!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values
      }
    });
  } catch (error) {
    console.error('Error exporting clubs:', error);
    throw error;
  }
};

// Export strokes gained data to a sheet
export const exportStrokesGainedToSheet = async (
  sheets: sheets_v4.Sheets, 
  spreadsheetId: string, 
  strokesGained: StrokesGained[]
): Promise<void> => {
  try {
    const headers = getHeadersForDataType('StrokesGained');
    const values = [headers];
    
    strokesGained.forEach(sg => {
      values.push(objectToRowValues(sg, headers));
    });
    
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: 'StrokesGained!A1',
      valueInputOption: 'RAW',
      requestBody: {
        values
      }
    });
  } catch (error) {
    console.error('Error exporting strokes gained data:', error);
    throw error;
  }
};

// Export all user data to a spreadsheet
export const exportAllData = async (
  tokens: any,
  userId: number,
  rounds: Round[],
  holes: Hole[],
  shots: Shot[],
  clubs: Club[],
  strokesGained: StrokesGained[]
): Promise<string> => {
  try {
    const sheets = createSheetsClient(tokens);
    const spreadsheetId = await createSpreadsheet(sheets, `Golf Tracker - User ${userId} - ${new Date().toISOString().split('T')[0]}`);
    
    // Export each data type to its own sheet
    await exportRoundsToSheet(sheets, spreadsheetId, rounds);
    await exportHolesToSheet(sheets, spreadsheetId, holes);
    await exportShotsToSheet(sheets, spreadsheetId, shots);
    await exportClubsToSheet(sheets, spreadsheetId, clubs);
    await exportStrokesGainedToSheet(sheets, spreadsheetId, strokesGained);
    
    return `https://docs.google.com/spreadsheets/d/${spreadsheetId}`;
  } catch (error) {
    console.error('Error exporting all data:', error);
    throw error;
  }
};

// Update Google OAuth credentials
export const updateCredentials = (
  clientId: string,
  clientSecret: string,
  redirectUri: string = 'http://localhost:5000/auth/google/callback'
) => {
  credentials = {
    client_id: clientId,
    client_secret: clientSecret,
    redirect_uri: redirectUri
  };
};