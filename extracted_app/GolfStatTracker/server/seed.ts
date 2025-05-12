import { db } from './db.js';
import { users, clubs, courses, rounds, holes, shots, strokesGained } from '@shared/schema';
import { eq } from 'drizzle-orm';

async function seed() {
  console.log('Starting database seeding...');
  
  // Seed users
  let userId = 1;
  try {
    const existingUser = await db.select().from(users).where(eq(users.id, userId)).execute();
    
    if (existingUser.length === 0) {
      console.log('Seeding user...');
      const [user] = await db.insert(users).values({
        username: 'golfer1',
        name: 'Golf Player',
        email: 'golfer@example.com',
        handicap: 15
      }).returning();
      
      userId = user.id;
      console.log(`Created user with ID: ${userId}`);
    } else {
      console.log('User already exists');
      userId = existingUser[0].id;
    }
  } catch (error) {
    console.error('Error seeding user:', error);
  }
  
  // Seed clubs
  try {
    const existingClubs = await db.select().from(clubs).where(eq(clubs.userId, userId)).execute();
    
    if (existingClubs.length === 0) {
      console.log('Seeding clubs...');
      
      // Create woods
      await db.insert(clubs).values([
        { userId, name: 'Driver', type: 'wood', loft: 10.5, brand: 'TaylorMade', averageDistance: 265 },
        { userId, name: '3 Wood', type: 'wood', loft: 15, brand: 'TaylorMade', averageDistance: 235 },
        { userId, name: '5 Wood', type: 'wood', loft: 18, brand: 'TaylorMade', averageDistance: 215 }
      ]);
      
      // Create hybrids
      await db.insert(clubs).values([
        { userId, name: '3 Hybrid', type: 'hybrid', loft: 19, brand: 'Titleist', averageDistance: 210 },
        { userId, name: '4 Hybrid', type: 'hybrid', loft: 22, brand: 'Titleist', averageDistance: 200 }
      ]);
      
      // Create irons
      await db.insert(clubs).values([
        { userId, name: '4 Iron', type: 'iron', loft: 23, brand: 'Callaway', averageDistance: 190 },
        { userId, name: '5 Iron', type: 'iron', loft: 26, brand: 'Callaway', averageDistance: 180 },
        { userId, name: '6 Iron', type: 'iron', loft: 30, brand: 'Callaway', averageDistance: 170 },
        { userId, name: '7 Iron', type: 'iron', loft: 34, brand: 'Callaway', averageDistance: 160 },
        { userId, name: '8 Iron', type: 'iron', loft: 38, brand: 'Callaway', averageDistance: 150 },
        { userId, name: '9 Iron', type: 'iron', loft: 42, brand: 'Callaway', averageDistance: 140 }
      ]);
      
      // Create wedges
      await db.insert(clubs).values([
        { userId, name: 'PW', type: 'wedge', loft: 46, brand: 'Vokey', averageDistance: 125 },
        { userId, name: 'GW', type: 'wedge', loft: 50, brand: 'Vokey', averageDistance: 110 },
        { userId, name: 'SW', type: 'wedge', loft: 54, brand: 'Vokey', averageDistance: 90 },
        { userId, name: 'LW', type: 'wedge', loft: 58, brand: 'Vokey', averageDistance: 75 }
      ]);
      
      // Create putter
      await db.insert(clubs).values([
        { userId, name: 'Putter', type: 'putter', loft: 3, brand: 'Odyssey', averageDistance: 0 }
      ]);
      
      console.log('Clubs seeded successfully');
    } else {
      console.log('Clubs already exist');
    }
  } catch (error) {
    console.error('Error seeding clubs:', error);
  }
  
  // Seed courses
  try {
    const existingCourses = await db.select().from(courses).execute();
    
    if (existingCourses.length === 0) {
      console.log('Seeding courses...');
      
      // Create sample courses
      await db.insert(courses).values([
        { 
          name: 'Pine Valley Golf Club', 
          location: 'Pine Valley, NJ', 
          par: 72, 
          holes: 18, 
          apiCourseId: '12345'
        },
        { 
          name: 'Augusta National Golf Club', 
          location: 'Augusta, GA', 
          par: 72, 
          holes: 18,
          apiCourseId: '23456'
        },
        { 
          name: 'Pebble Beach Golf Links', 
          location: 'Pebble Beach, CA', 
          par: 72, 
          holes: 18,
          apiCourseId: '34567'
        }
      ]);
      
      console.log('Courses seeded successfully');
    } else {
      console.log('Courses already exist');
    }
  } catch (error) {
    console.error('Error seeding courses:', error);
  }
  
  // Seed a sample round with holes and shots
  try {
    const existingRounds = await db.select().from(rounds).where(eq(rounds.userId, userId)).execute();
    
    if (existingRounds.length === 0) {
      console.log('Seeding a sample round...');
      
      // Get first course
      const [course] = await db.select().from(courses).limit(1).execute();
      
      if (course) {
        // Create a round
        const [round] = await db.insert(rounds).values({
          userId,
          date: new Date().toISOString().split('T')[0],
          courseId: course.id,
          courseName: course.name,
          weather: 'Sunny, 75°F',
          teeBox: 'Blue',
          teeBoxGender: 'Men',
          totalScore: 85,
          frontNine: 43,
          backNine: 42,
          notes: 'Sample round created during seeding'
        }).returning();
        
        console.log(`Created round with ID: ${round.id}`);
        
        // Create holes and shots
        for (let holeNumber = 1; holeNumber <= 18; holeNumber++) {
          // Determine par based on hole number (just for sample data)
          const par = holeNumber % 5 === 0 ? 5 : (holeNumber % 4 === 0 ? 3 : 4);
          
          // Create hole
          const [hole] = await db.insert(holes).values({
            roundId: round.id,
            holeNumber,
            par,
            distance: 150 + (holeNumber * 15),
            score: par + (holeNumber % 3 === 0 ? 1 : 0),
            fairwayHit: holeNumber % 2 === 0,
            greenInRegulation: holeNumber % 3 === 0,
            numPutts: holeNumber % 3 === 0 ? 1 : 2,
            strokesGained: ((holeNumber % 3) - 1) * 0.5 // -0.5, 0, or 0.5
          }).returning();
          
          // Add shots for this hole
          if (par === 4 || par === 5) {
            // Add tee shot
            await db.insert(shots).values({
              holeId: hole.id,
              shotNumber: 1,
              clubId: 1, // Driver
              clubName: 'Driver',
              distanceToTarget: par === 5 ? 500 : 400,
              shotDistance: 260,
              shotType: 'tee',
              successfulStrike: true,
              outcome: holeNumber % 2 === 0 ? 'fairway' : 'rough',
              direction: holeNumber % 3 === 0 ? 'center' : (holeNumber % 3 === 1 ? 'left' : 'right'),
              notes: ''
            });
            
            // Add approach shot
            await db.insert(shots).values({
              holeId: hole.id,
              shotNumber: 2,
              clubId: 8, // 7 Iron
              clubName: '7 Iron',
              distanceToTarget: 150,
              shotDistance: 155,
              shotType: 'approach',
              successfulStrike: true,
              outcome: holeNumber % 3 === 0 ? 'green' : 'rough',
              direction: holeNumber % 3 === 0 ? 'center' : (holeNumber % 3 === 1 ? 'left' : 'right'),
              notes: ''
            });
            
            if (par === 5) {
              // Add third shot for par 5
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: 3,
                clubId: 12, // PW
                clubName: 'PW',
                distanceToTarget: 100,
                shotDistance: 105,
                shotType: 'approach',
                successfulStrike: true,
                outcome: 'green',
                direction: 'center',
                notes: ''
              });
            }
            
            // Add putts
            if (holeNumber % 3 === 0) {
              // One putt
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: par === 5 ? 4 : 3,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'hole',
                puttLength: 8,
                notes: ''
              });
            } else {
              // Two putts
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: par === 5 ? 4 : 3,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'miss',
                puttLength: 20,
                notes: ''
              });
              
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: par === 5 ? 5 : 4,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'hole',
                puttLength: 3,
                notes: ''
              });
            }
          } else if (par === 3) {
            // Par 3 - tee shot
            await db.insert(shots).values({
              holeId: hole.id,
              shotNumber: 1,
              clubId: 8, // 7 Iron
              clubName: '7 Iron',
              distanceToTarget: 155,
              shotDistance: 160,
              shotType: 'tee',
              successfulStrike: true,
              outcome: holeNumber % 3 === 0 ? 'green' : 'rough',
              direction: holeNumber % 3 === 0 ? 'center' : (holeNumber % 3 === 1 ? 'left' : 'right'),
              notes: ''
            });
            
            // Add putts
            if (holeNumber % 3 === 0) {
              // One putt
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: 2,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'hole',
                puttLength: 6,
                notes: ''
              });
            } else {
              // Two putts
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: 2,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'miss',
                puttLength: 18,
                notes: ''
              });
              
              await db.insert(shots).values({
                holeId: hole.id,
                shotNumber: 3,
                clubId: 16, // Putter
                clubName: 'Putter',
                distanceToTarget: 0,
                shotDistance: 0,
                shotType: 'putt',
                successfulStrike: true,
                outcome: 'hole',
                puttLength: 2,
                notes: ''
              });
            }
          }
        }
        
        // Add strokes gained data for the round
        await db.insert(strokesGained).values({
          userId,
          roundId: round.id,
          date: new Date().toISOString().split('T')[0],
          offTee: 0.7,
          approach: -0.3,
          aroundGreen: 0.2,
          putting: 1.4,
          total: 2.0
        });
        
        console.log('Sample round with holes and shots seeded successfully');
      } else {
        console.log('No courses found to create a sample round');
      }
    } else {
      console.log('Rounds already exist');
    }
  } catch (error) {
    console.error('Error seeding rounds:', error);
  }
  
  console.log('Database seeding completed');
}

// Run the seed function
seed().catch(error => {
  console.error('Failed to seed database:', error);
  process.exit(1);
});