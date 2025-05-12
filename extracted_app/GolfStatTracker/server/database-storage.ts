import { IStorage } from './storage';
import { db } from './db';
import { eq } from 'drizzle-orm';
import {
  users, clubs, courses, rounds, holes, shots, strokesGained,
  User, InsertUser, Club, InsertClub, Course, InsertCourse,
  Round, InsertRound, Hole, InsertHole, Shot, InsertShot,
  StrokesGained, InsertStrokesGained
} from '@shared/schema';

export class DatabaseStorage implements IStorage {
  // User methods
  async getUser(id: number): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.id, id));
    return user;
  }
  
  async getUserByUsername(username: string): Promise<User | undefined> {
    const [user] = await db.select().from(users).where(eq(users.username, username));
    return user;
  }
  
  async createUser(insertUser: InsertUser): Promise<User> {
    const [user] = await db.insert(users).values(insertUser).returning();
    return user;
  }

  async updateUser(id: number, userData: Partial<User>): Promise<User> {
    const [updatedUser] = await db
      .update(users)
      .set(userData)
      .where(eq(users.id, id))
      .returning();
    return updatedUser;
  }
  
  // Club methods
  async getClub(id: number): Promise<Club | undefined> {
    const [club] = await db.select().from(clubs).where(eq(clubs.id, id));
    return club;
  }
  
  async getClubsByUserId(userId: number): Promise<Club[]> {
    return db.select().from(clubs).where(eq(clubs.userId, userId));
  }
  
  async createClub(insertClub: InsertClub): Promise<Club> {
    const [club] = await db.insert(clubs).values(insertClub).returning();
    return club;
  }
  
  async updateClub(id: number, clubData: Partial<Club>): Promise<Club> {
    const [updatedClub] = await db
      .update(clubs)
      .set(clubData)
      .where(eq(clubs.id, id))
      .returning();
    return updatedClub;
  }
  
  async deleteClub(id: number): Promise<void> {
    await db.delete(clubs).where(eq(clubs.id, id));
  }
  
  // Course methods
  async getCourse(id: number): Promise<Course | undefined> {
    const [course] = await db.select().from(courses).where(eq(courses.id, id));
    return course;
  }
  
  async getCourseByName(name: string): Promise<Course | undefined> {
    const [course] = await db.select().from(courses).where(eq(courses.name, name));
    return course;
  }
  
  async createCourse(insertCourse: InsertCourse): Promise<Course> {
    const [course] = await db.insert(courses).values(insertCourse).returning();
    return course;
  }
  
  // Round methods
  async getRound(id: number): Promise<Round | undefined> {
    const [round] = await db.select().from(rounds).where(eq(rounds.id, id));
    return round;
  }
  
  async getRoundsByUserId(userId: number): Promise<Round[]> {
    return db.select().from(rounds).where(eq(rounds.userId, userId));
  }
  
  async createRound(insertRound: InsertRound): Promise<Round> {
    const [round] = await db.insert(rounds).values(insertRound).returning();
    return round;
  }
  
  async updateRound(id: number, roundData: Partial<Round>): Promise<Round> {
    const [updatedRound] = await db
      .update(rounds)
      .set(roundData)
      .where(eq(rounds.id, id))
      .returning();
    return updatedRound;
  }
  
  async deleteRound(id: number): Promise<void> {
    await db.delete(rounds).where(eq(rounds.id, id));
  }
  
  // Hole methods
  async getHole(id: number): Promise<Hole | undefined> {
    const [hole] = await db.select().from(holes).where(eq(holes.id, id));
    return hole;
  }
  
  async getHolesByRoundId(roundId: number): Promise<Hole[]> {
    return db.select().from(holes).where(eq(holes.roundId, roundId));
  }
  
  async createHole(insertHole: InsertHole): Promise<Hole> {
    const [hole] = await db.insert(holes).values(insertHole).returning();
    return hole;
  }
  
  async updateHole(id: number, holeData: Partial<Hole>): Promise<Hole> {
    const [updatedHole] = await db
      .update(holes)
      .set(holeData)
      .where(eq(holes.id, id))
      .returning();
    return updatedHole;
  }
  
  // Shot methods
  async getShot(id: number): Promise<Shot | undefined> {
    const [shot] = await db.select().from(shots).where(eq(shots.id, id));
    return shot;
  }
  
  async getShotsByHoleId(holeId: number): Promise<Shot[]> {
    return db.select().from(shots).where(eq(shots.holeId, holeId));
  }
  
  async createShot(insertShot: InsertShot): Promise<Shot> {
    const [shot] = await db.insert(shots).values(insertShot).returning();
    return shot;
  }
  
  async updateShot(id: number, shotData: Partial<Shot>): Promise<Shot> {
    const [updatedShot] = await db
      .update(shots)
      .set(shotData)
      .where(eq(shots.id, id))
      .returning();
    return updatedShot;
  }
  
  // Strokes gained methods
  async getStrokesGained(id: number): Promise<StrokesGained | undefined> {
    const [sg] = await db.select().from(strokesGained).where(eq(strokesGained.id, id));
    return sg;
  }
  
  async getStrokesGainedByUserId(userId: number): Promise<StrokesGained[]> {
    return db.select().from(strokesGained).where(eq(strokesGained.userId, userId));
  }
  
  async getStrokesGainedByRoundId(roundId: number): Promise<StrokesGained | undefined> {
    // Check if there are any strokes gained records for this round
    const records = await db.select().from(strokesGained).where(eq(strokesGained.roundId, roundId));
    
    // If we have records, return the most recent one
    if (records && records.length > 0) {
      // Sort by id in descending order to get the most recent entry
      const sortedRecords = [...records].sort((a, b) => b.id - a.id);
      return sortedRecords[0];
    }
    
    return undefined;
  }
  
  async createStrokesGained(insertStrokesGained: InsertStrokesGained): Promise<StrokesGained> {
    const [sg] = await db.insert(strokesGained).values(insertStrokesGained).returning();
    return sg;
  }
  
  async updateStrokesGained(id: number, sgData: Partial<StrokesGained>): Promise<StrokesGained> {
    const [updatedSg] = await db
      .update(strokesGained)
      .set(sgData)
      .where(eq(strokesGained.id, id))
      .returning();
    return updatedSg;
  }
}