import { 
  type User, 
  type InsertUser, 
  type Club, 
  type InsertClub,
  type Course, 
  type InsertCourse,
  type Round, 
  type InsertRound,
  type Hole, 
  type InsertHole,
  type Shot, 
  type InsertShot,
  type StrokesGained, 
  type InsertStrokesGained
} from "@shared/schema";

export interface IStorage {
  // User methods
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  updateUser(id: number, user: Partial<User>): Promise<User>;
  
  // Club methods
  getClub(id: number): Promise<Club | undefined>;
  getClubsByUserId(userId: number): Promise<Club[]>;
  createClub(club: InsertClub): Promise<Club>;
  updateClub(id: number, club: Partial<Club>): Promise<Club>;
  deleteClub(id: number): Promise<void>;
  
  // Course methods
  getCourse(id: number): Promise<Course | undefined>;
  getCourseByName(name: string): Promise<Course | undefined>;
  createCourse(course: InsertCourse): Promise<Course>;
  
  // Round methods
  getRound(id: number): Promise<Round | undefined>;
  getRoundsByUserId(userId: number): Promise<Round[]>;
  createRound(round: InsertRound): Promise<Round>;
  updateRound(id: number, round: Partial<Round>): Promise<Round>;
  deleteRound(id: number): Promise<void>;
  
  // Hole methods
  getHole(id: number): Promise<Hole | undefined>;
  getHolesByRoundId(roundId: number): Promise<Hole[]>;
  createHole(hole: InsertHole): Promise<Hole>;
  updateHole(id: number, hole: Partial<Hole>): Promise<Hole>;
  
  // Shot methods
  getShot(id: number): Promise<Shot | undefined>;
  getShotsByHoleId(holeId: number): Promise<Shot[]>;
  createShot(shot: InsertShot): Promise<Shot>;
  updateShot(id: number, shot: Partial<Shot>): Promise<Shot>;
  
  // Strokes gained methods
  getStrokesGained(id: number): Promise<StrokesGained | undefined>;
  getStrokesGainedByUserId(userId: number): Promise<StrokesGained[]>;
  getStrokesGainedByRoundId(roundId: number): Promise<StrokesGained | undefined>;
  createStrokesGained(strokesGained: InsertStrokesGained): Promise<StrokesGained>;
  updateStrokesGained(id: number, strokesGained: Partial<StrokesGained>): Promise<StrokesGained>;
}

export class MemStorage implements IStorage {
  private users: Map<number, User>;
  private clubs: Map<number, Club>;
  private courses: Map<number, Course>;
  private rounds: Map<number, Round>;
  private holes: Map<number, Hole>;
  private shots: Map<number, Shot>;
  private strokesGained: Map<number, StrokesGained>;
  
  private currentUserId: number;
  private currentClubId: number;
  private currentCourseId: number;
  private currentRoundId: number;
  private currentHoleId: number;
  private currentShotId: number;
  private currentStrokesGainedId: number;

  constructor() {
    this.users = new Map();
    this.clubs = new Map();
    this.courses = new Map();
    this.rounds = new Map();
    this.holes = new Map();
    this.shots = new Map();
    this.strokesGained = new Map();
    
    this.currentUserId = 1;
    this.currentClubId = 1;
    this.currentCourseId = 1;
    this.currentRoundId = 1;
    this.currentHoleId = 1;
    this.currentShotId = 1;
    this.currentStrokesGainedId = 1;
    
    // Add some sample data
    this.initSampleData();
  }
  
  private initSampleData() {
    // Sample user
    this.createUser({
      username: "johndoe",
      password: "password",
      firstName: "John",
      lastName: "Doe",
      email: "john.doe@example.com",
      handicap: 12.4,
      homeCourse: "Pebble Beach Golf Links"
    });
    
    // Sample clubs
    const clubs = [
      { userId: 1, name: "Driver", type: "driver", distance: 267, isInBag: true },
      { userId: 1, name: "3 Wood", type: "wood", distance: 235, isInBag: true },
      { userId: 1, name: "5 Wood", type: "wood", distance: 215, isInBag: true },
      { userId: 1, name: "3 Iron", type: "iron", distance: 200, isInBag: true },
      { userId: 1, name: "4 Iron", type: "iron", distance: 190, isInBag: true },
      { userId: 1, name: "5 Iron", type: "iron", distance: 185, isInBag: true },
      { userId: 1, name: "6 Iron", type: "iron", distance: 175, isInBag: true },
      { userId: 1, name: "7 Iron", type: "iron", distance: 165, isInBag: true },
      { userId: 1, name: "8 Iron", type: "iron", distance: 155, isInBag: true },
      { userId: 1, name: "9 Iron", type: "iron", distance: 140, isInBag: true },
      { userId: 1, name: "PW", type: "wedge", distance: 125, isInBag: true },
      { userId: 1, name: "GW", type: "wedge", distance: 110, isInBag: true },
      { userId: 1, name: "SW", type: "wedge", distance: 95, isInBag: true },
      { userId: 1, name: "LW", type: "wedge", distance: 80, isInBag: true },
      { userId: 1, name: "Putter", type: "putter", distance: 0, isInBag: true }
    ];
    
    clubs.forEach(club => this.createClub(club));
    
    // Sample courses
    const courses = [
      { name: "Pebble Beach Golf Links", city: "Pebble Beach", state: "CA", country: "USA", numHoles: 18 },
      { name: "St Andrews Links", city: "St Andrews", state: "", country: "Scotland", numHoles: 18 },
      { name: "Pinehurst No. 2", city: "Pinehurst", state: "NC", country: "USA", numHoles: 18 }
    ];
    
    courses.forEach(course => this.createCourse(course));
    
    // Sample rounds
    const rounds = [
      { 
        userId: 1, 
        courseId: 1, 
        courseName: "Pebble Beach Golf Links", 
        date: "2023-06-15", 
        weather: "sunny", 
        teeBox: "middle",
        totalScore: 82,
        relativeToPar: 10,
        fairwaysHit: 9,
        fairwaysTotal: 14,
        greensInRegulation: 9,
        totalPutts: 32,
        notes: ""
      },
      { 
        userId: 1, 
        courseId: 2, 
        courseName: "St Andrews Links", 
        date: "2023-06-08", 
        weather: "windy", 
        teeBox: "back",
        totalScore: 78,
        relativeToPar: 6,
        fairwaysHit: 10,
        fairwaysTotal: 14,
        greensInRegulation: 11,
        totalPutts: 29,
        notes: ""
      },
      { 
        userId: 1, 
        courseId: 3, 
        courseName: "Pinehurst No. 2", 
        date: "2023-05-24", 
        weather: "sunny", 
        teeBox: "back",
        totalScore: 85,
        relativeToPar: 13,
        fairwaysHit: 8,
        fairwaysTotal: 14,
        greensInRegulation: 8,
        totalPutts: 33,
        notes: ""
      }
    ];
    
    rounds.forEach(round => this.createRound(round));
    
    // Add sample holes and shots for the first round
    for (let i = 1; i <= 18; i++) {
      const hole: InsertHole = {
        roundId: 1,
        holeNumber: i,
        par: i % 5 === 0 ? 5 : i % 4 === 0 ? 3 : 4,
        distance: 150 + (i * 15),
        score: i % 5 === 0 ? 6 : i % 4 === 0 ? 3 : 4,
        fairwayHit: i % 3 === 0,
        greenInRegulation: i % 2 === 0,
        numPutts: i % 4 === 0 ? 1 : 2,
        strokesGained: i % 2 === 0 ? 0.5 : -0.5
      };
      
      const createdHole = this.createHole(hole);
      
      // Add tee shot
      this.createShot({
        holeId: createdHole.id,
        shotNumber: 1,
        clubId: 1, // Driver
        clubName: "Driver",
        distanceToTarget: 350,
        shotDistance: 265,
        shotType: "tee",
        successfulStrike: true,
        outcome: i % 3 === 0 ? "fairway" : "rough",
        direction: i % 3 === 0 ? "center" : i % 3 === 1 ? "left" : "right",
        notes: ""
      });
      
      // Add approach shot
      this.createShot({
        holeId: createdHole.id,
        shotNumber: 2,
        clubId: 7, // 7 Iron
        clubName: "7 Iron",
        distanceToTarget: 150,
        shotDistance: 150,
        shotType: "approach",
        successfulStrike: true,
        outcome: i % 2 === 0 ? "green" : "rough",
        direction: i % 3 === 0 ? "center" : i % 3 === 1 ? "left" : "right",
        notes: ""
      });
      
      // Add putts
      if (i % 4 === 0) {
        // One putt
        this.createShot({
          holeId: createdHole.id,
          shotNumber: 3,
          clubId: 15, // Putter
          clubName: "Putter",
          distanceToTarget: 0,
          shotDistance: 0,
          shotType: "putt",
          successfulStrike: true,
          outcome: "hole",
          puttLength: 8,
          notes: ""
        });
      } else {
        // Two putts
        this.createShot({
          holeId: createdHole.id,
          shotNumber: 3,
          clubId: 15, // Putter
          clubName: "Putter",
          distanceToTarget: 0,
          shotDistance: 0,
          shotType: "putt",
          successfulStrike: false,
          outcome: "lip",
          puttLength: 25,
          notes: ""
        });
        
        this.createShot({
          holeId: createdHole.id,
          shotNumber: 4,
          clubId: 15, // Putter
          clubName: "Putter",
          distanceToTarget: 0,
          shotDistance: 0,
          shotType: "putt",
          successfulStrike: true,
          outcome: "hole",
          puttLength: 3,
          notes: ""
        });
      }
    }
    
    // Add strokes gained data
    this.createStrokesGained({
      userId: 1,
      date: "2023-06-15",
      offTee: 0.7,
      approach: -0.3,
      aroundGreen: 0.2,
      putting: 1.4,
      total: 2.0
    });
  }

  // User methods
  async getUser(id: number): Promise<User | undefined> {
    return this.users.get(id);
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return Array.from(this.users.values()).find(
      (user) => user.username === username,
    );
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    const id = this.currentUserId++;
    const user: User = { 
      ...insertUser, 
      id,
      createdAt: new Date()
    };
    this.users.set(id, user);
    return user;
  }
  
  async updateUser(id: number, userData: Partial<User>): Promise<User> {
    const user = await this.getUser(id);
    if (!user) {
      throw new Error(`User with id ${id} not found`);
    }
    
    const updatedUser = { ...user, ...userData };
    this.users.set(id, updatedUser);
    return updatedUser;
  }
  
  // Club methods
  async getClub(id: number): Promise<Club | undefined> {
    return this.clubs.get(id);
  }
  
  async getClubsByUserId(userId: number): Promise<Club[]> {
    return Array.from(this.clubs.values()).filter(club => club.userId === userId);
  }
  
  async createClub(insertClub: InsertClub): Promise<Club> {
    const id = this.currentClubId++;
    const club: Club = { ...insertClub, id };
    this.clubs.set(id, club);
    return club;
  }
  
  async updateClub(id: number, clubData: Partial<Club>): Promise<Club> {
    const club = await this.getClub(id);
    if (!club) {
      throw new Error(`Club with id ${id} not found`);
    }
    
    const updatedClub = { ...club, ...clubData };
    this.clubs.set(id, updatedClub);
    return updatedClub;
  }
  
  async deleteClub(id: number): Promise<void> {
    this.clubs.delete(id);
  }
  
  // Course methods
  async getCourse(id: number): Promise<Course | undefined> {
    return this.courses.get(id);
  }
  
  async getCourseByName(name: string): Promise<Course | undefined> {
    return Array.from(this.courses.values()).find(course => course.name === name);
  }
  
  async createCourse(insertCourse: InsertCourse): Promise<Course> {
    const id = this.currentCourseId++;
    const course: Course = { ...insertCourse, id };
    this.courses.set(id, course);
    return course;
  }
  
  // Round methods
  async getRound(id: number): Promise<Round | undefined> {
    return this.rounds.get(id);
  }
  
  async getRoundsByUserId(userId: number): Promise<Round[]> {
    return Array.from(this.rounds.values()).filter(round => round.userId === userId);
  }
  
  async createRound(insertRound: InsertRound): Promise<Round> {
    const id = this.currentRoundId++;
    const round: Round = { ...insertRound, id };
    this.rounds.set(id, round);
    return round;
  }
  
  async updateRound(id: number, roundData: Partial<Round>): Promise<Round> {
    const round = await this.getRound(id);
    if (!round) {
      throw new Error(`Round with id ${id} not found`);
    }
    
    const updatedRound = { ...round, ...roundData };
    this.rounds.set(id, updatedRound);
    return updatedRound;
  }
  
  async deleteRound(id: number): Promise<void> {
    // Delete all holes associated with this round
    const holesForRound = await this.getHolesByRoundId(id);
    for (const hole of holesForRound) {
      // Delete all shots associated with this hole
      const shotsForHole = await this.getShotsByHoleId(hole.id);
      for (const shot of shotsForHole) {
        this.shots.delete(shot.id);
      }
      this.holes.delete(hole.id);
    }
    
    this.rounds.delete(id);
  }
  
  // Hole methods
  async getHole(id: number): Promise<Hole | undefined> {
    return this.holes.get(id);
  }
  
  async getHolesByRoundId(roundId: number): Promise<Hole[]> {
    return Array.from(this.holes.values())
      .filter(hole => hole.roundId === roundId)
      .sort((a, b) => a.holeNumber - b.holeNumber);
  }
  
  async createHole(insertHole: InsertHole): Promise<Hole> {
    const id = this.currentHoleId++;
    const hole: Hole = { ...insertHole, id };
    this.holes.set(id, hole);
    return hole;
  }
  
  async updateHole(id: number, holeData: Partial<Hole>): Promise<Hole> {
    const hole = await this.getHole(id);
    if (!hole) {
      throw new Error(`Hole with id ${id} not found`);
    }
    
    const updatedHole = { ...hole, ...holeData };
    this.holes.set(id, updatedHole);
    return updatedHole;
  }
  
  // Shot methods
  async getShot(id: number): Promise<Shot | undefined> {
    return this.shots.get(id);
  }
  
  async getShotsByHoleId(holeId: number): Promise<Shot[]> {
    return Array.from(this.shots.values())
      .filter(shot => shot.holeId === holeId)
      .sort((a, b) => a.shotNumber - b.shotNumber);
  }
  
  async createShot(insertShot: InsertShot): Promise<Shot> {
    const id = this.currentShotId++;
    const shot: Shot = { ...insertShot, id };
    this.shots.set(id, shot);
    return shot;
  }
  
  async updateShot(id: number, shotData: Partial<Shot>): Promise<Shot> {
    const shot = await this.getShot(id);
    if (!shot) {
      throw new Error(`Shot with id ${id} not found`);
    }
    
    const updatedShot = { ...shot, ...shotData };
    this.shots.set(id, updatedShot);
    return updatedShot;
  }
  
  // Strokes gained methods
  async getStrokesGained(id: number): Promise<StrokesGained | undefined> {
    return this.strokesGained.get(id);
  }
  
  async getStrokesGainedByUserId(userId: number): Promise<StrokesGained[]> {
    return Array.from(this.strokesGained.values())
      .filter(sg => sg.userId === userId)
      .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
  }
  
  async getStrokesGainedByRoundId(roundId: number): Promise<StrokesGained | undefined> {
    // Get all strokes gained records for this round
    const records = Array.from(this.strokesGained.values())
      .filter(sg => sg.roundId === roundId);
      
    // If we have records, return the most recent one (highest id)
    if (records && records.length > 0) {
      return records.sort((a, b) => b.id - a.id)[0];
    }
    
    return undefined;
  }
  
  async createStrokesGained(insertStrokesGained: InsertStrokesGained): Promise<StrokesGained> {
    const id = this.currentStrokesGainedId++;
    const strokesGained: StrokesGained = { ...insertStrokesGained, id };
    this.strokesGained.set(id, strokesGained);
    return strokesGained;
  }
  
  async updateStrokesGained(id: number, strokesGainedData: Partial<StrokesGained>): Promise<StrokesGained> {
    const strokesGained = await this.getStrokesGained(id);
    if (!strokesGained) {
      throw new Error(`Strokes gained with id ${id} not found`);
    }
    
    const updatedStrokesGained = { ...strokesGained, ...strokesGainedData };
    this.strokesGained.set(id, updatedStrokesGained);
    return updatedStrokesGained;
  }
}

// Use DatabaseStorage instead of MemStorage
import { DatabaseStorage } from "./database-storage.js";
export const storage = new DatabaseStorage();
