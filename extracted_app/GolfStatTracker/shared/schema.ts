import { pgTable, text, serial, integer, boolean, date, jsonb, real, timestamp } from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

// User model
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  firstName: text("first_name"),
  lastName: text("last_name"),
  email: text("email"),
  handicap: real("handicap"),
  homeCourse: text("home_course"),
  profilePicture: text("profile_picture"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Golf club model
export const clubs = pgTable("clubs", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  name: text("name").notNull(),
  type: text("type").notNull(), // driver, wood, iron, wedge, putter
  distance: integer("distance"), // average distance in yards
  isInBag: boolean("is_in_bag").default(true),
});

// Course model
export const courses = pgTable("courses", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  city: text("city"),
  state: text("state"),
  country: text("country"),
  numHoles: integer("num_holes").default(18),
  apiCourseId: integer("api_course_id"), // ID from the Golf Course API
  clubName: text("club_name"), // Name of the golf club
  courseName: text("course_name"), // Name of the specific course at the club
  latitude: real("latitude"), // Geolocation data
  longitude: real("longitude"), // Geolocation data
  address: text("address"), // Full address
  holeDetails: jsonb("hole_details"), // Array of hole information (par, distance, handicap)
});

// Round model
export const rounds = pgTable("rounds", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  courseId: integer("course_id").notNull(),
  courseName: text("course_name").notNull(), // Denormalized for convenience
  date: date("date").notNull(),
  weather: text("weather"), // sunny, cloudy, rainy, windy
  teeBox: text("tee_box"), // Name of the tee box (e.g., "Blue", "Red", "Gold")
  teeBoxGender: text("tee_box_gender"), // "male" or "female" 
  courseRating: real("course_rating"), // Course rating for the selected tee box
  slopeRating: integer("slope_rating"), // Slope rating for the selected tee box
  totalYards: integer("total_yards"), // Total length in yards for the selected tee box
  totalScore: integer("total_score"),
  relativeToPar: integer("relative_to_par"),
  fairwaysHit: integer("fairways_hit"),
  fairwaysTotal: integer("fairways_total"),
  greensInRegulation: integer("greens_in_regulation"),
  totalPutts: integer("total_putts"),
  temperature: integer("temperature"), // Temperature in Celsius
  windSpeed: integer("wind_speed"), // Wind speed in mph
  notes: text("notes"),
});

// Hole model
export const holes = pgTable("holes", {
  id: serial("id").primaryKey(),
  roundId: integer("round_id").notNull(),
  holeNumber: integer("hole_number").notNull(),
  par: integer("par").notNull(),
  distance: integer("distance"), // in yards
  score: integer("score"),
  fairwayHit: boolean("fairway_hit"),
  greenInRegulation: boolean("green_in_regulation"),
  numPutts: integer("num_putts"),
  numPenalties: integer("num_penalties").default(0),
  upAndDown: boolean("up_and_down"),
  sandSave: boolean("sand_save"),
  strokesGained: real("strokes_gained"),
});

// Shot model
export const shots = pgTable("shots", {
  id: serial("id").primaryKey(),
  holeId: integer("hole_id").notNull(),
  shotNumber: integer("shot_number").notNull(),
  clubId: integer("club_id"),
  clubName: text("club_name").notNull(), // Denormalized for convenience
  distanceToTarget: integer("distance_to_target"), // in yards
  shotDistance: integer("shot_distance"), // actual distance hit
  shotType: text("shot_type"), // tee, approach, chip, putt, bunker, etc.
  successfulStrike: boolean("successful_strike"),
  outcome: text("outcome"), // fairway, rough, green, bunker, hazard, OB
  direction: text("direction"), // left, right, center
  puttLength: integer("putt_length"), // in feet (if shot_type is putt)
  notes: text("notes"),
});

// Strokes gained categories for tracking performance
export const strokesGained = pgTable("strokes_gained", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull(),
  roundId: integer("round_id"),
  date: date("date").notNull(),
  offTee: real("off_tee"),
  approach: real("approach"),
  aroundGreen: real("around_green"),
  putting: real("putting"),
  total: real("total"),
});

// Insert schemas
export const insertUserSchema = createInsertSchema(users).omit({ id: true, createdAt: true });
export const insertClubSchema = createInsertSchema(clubs).omit({ id: true });
export const insertCourseSchema = createInsertSchema(courses).omit({ id: true });
export const insertRoundSchema = createInsertSchema(rounds).omit({ id: true });
export const insertHoleSchema = createInsertSchema(holes).omit({ id: true });
export const insertShotSchema = createInsertSchema(shots).omit({ id: true });
export const insertStrokesGainedSchema = createInsertSchema(strokesGained).omit({ id: true });

// Types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;

export type Club = typeof clubs.$inferSelect;
export type InsertClub = z.infer<typeof insertClubSchema>;

export type Course = typeof courses.$inferSelect;
export type InsertCourse = z.infer<typeof insertCourseSchema>;

export type Round = typeof rounds.$inferSelect;
export type InsertRound = z.infer<typeof insertRoundSchema>;

export type Hole = typeof holes.$inferSelect;
export type InsertHole = z.infer<typeof insertHoleSchema>;

export type Shot = typeof shots.$inferSelect;
export type InsertShot = z.infer<typeof insertShotSchema>;

export type StrokesGained = typeof strokesGained.$inferSelect;
export type InsertStrokesGained = z.infer<typeof insertStrokesGainedSchema>;

// Extended schemas for form validation
export const roundFormSchema = insertRoundSchema.extend({
  courseName: z.string().min(3, "Course name must be at least 3 characters"),
  date: z.union([z.string(), z.date()]),
  teeBox: z.string().min(1, "Tee box is required"),
  teeBoxGender: z.enum(["male", "female"]).optional(),
  courseRating: z.number().optional(),
  slopeRating: z.number().optional(),
  totalYards: z.number().optional(),
  weather: z.enum(["sunny", "cloudy", "rainy", "windy"]),
  temperature: z.union([z.string(), z.number()]).optional(),
  windSpeed: z.union([z.string(), z.number()]).optional(),
});

export const shotFormSchema = insertShotSchema.extend({
  clubName: z.string().min(1, "Club selection is required"),
  shotDistance: z.number().min(0, "Distance must be a positive number"),
  outcome: z.enum(["fairway", "rough", "green", "bunker", "hazard", "ob"]),
  direction: z.enum([
    "short-left", "short", "short-right", 
    "middle-left", "middle", "middle-right", 
    "long-left", "long", "long-right"
  ]),
});

export const holeFormSchema = insertHoleSchema.extend({
  score: z.number().min(1, "Score must be at least 1"),
  numPutts: z.number().min(0, "Number of putts must be a non-negative number"),
});

export const clubFormSchema = insertClubSchema.extend({
  name: z.string().min(1, "Club name is required"),
  type: z.enum(["driver", "wood", "hybrid", "iron", "wedge", "putter"]),
  distance: z.number().min(0, "Distance must be a non-negative number"),
});

// Define the relationships between tables
export const usersRelations = relations(users, ({ many }) => ({
  clubs: many(clubs),
  rounds: many(rounds),
  strokesGained: many(strokesGained)
}));

export const clubsRelations = relations(clubs, ({ one }) => ({
  user: one(users, {
    fields: [clubs.userId],
    references: [users.id]
  })
}));

export const coursesRelations = relations(courses, ({ many }) => ({
  rounds: many(rounds)
}));

export const roundsRelations = relations(rounds, ({ one, many }) => ({
  user: one(users, {
    fields: [rounds.userId],
    references: [users.id]
  }),
  course: one(courses, {
    fields: [rounds.courseId],
    references: [courses.id]
  }),
  holes: many(holes),
  strokesGained: many(strokesGained)
}));

export const holesRelations = relations(holes, ({ one, many }) => ({
  round: one(rounds, {
    fields: [holes.roundId],
    references: [rounds.id]
  }),
  shots: many(shots)
}));

export const shotsRelations = relations(shots, ({ one }) => ({
  hole: one(holes, {
    fields: [shots.holeId],
    references: [holes.id]
  }),
  club: one(clubs, {
    fields: [shots.clubId],
    references: [clubs.id]
  })
}));

export const strokesGainedRelations = relations(strokesGained, ({ one }) => ({
  user: one(users, {
    fields: [strokesGained.userId],
    references: [users.id]
  }),
  round: one(rounds, {
    fields: [strokesGained.roundId],
    references: [rounds.id]
  })
}));
