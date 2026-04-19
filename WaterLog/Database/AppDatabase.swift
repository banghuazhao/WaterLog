//
// Created by Banghua Zhao on 19/04/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import GRDB
import SQLiteData

enum AppDatabase {
  static func makeDatabaseQueue() throws -> DatabaseQueue {
    let url = try databaseURL()
    var configuration = Configuration()
    #if DEBUG
      configuration.prepareDatabase { db in
        db.trace { print($0.expandedDescription) }
      }
    #endif
    let queue = try DatabaseQueue(path: url.path, configuration: configuration)
    try migrate(queue)
    return queue
  }

  private static func databaseURL() throws -> URL {
    let fm = FileManager.default
    let dir = try fm.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
      .appending(path: "WaterLog", directoryHint: .isDirectory)
    if !fm.fileExists(atPath: dir.path) {
      try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir.appending(path: "waterlog.sqlite")
  }

  private static func migrate(_ dbWriter: DatabaseQueue) throws {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1") { db in
      try createDrinkTables(db)
      try createAppSettingsTable(db)
      try seedIfNeeded(db)
    }

    migrator.registerMigration("v3_milkAccentVisibility") { db in
      try db.execute(
        sql: """
          UPDATE "drinkTypes"
          SET "tintHex" = '#7C9CBF'
          WHERE "name" = 'Milk' AND (
            UPPER("tintHex") = '#F8FAFC' OR UPPER("tintHex") = 'F8FAFC'
          )
          """
      )
    }

    try migrator.migrate(dbWriter)
  }

  private nonisolated static func createDrinkTables(_ db: Database) throws {
    try #sql(
      """
      CREATE TABLE "drinkTypes" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        "name" TEXT NOT NULL,
        "iconName" TEXT NOT NULL,
        "tintHex" TEXT NOT NULL,
        "sortOrder" INTEGER NOT NULL,
        "createdAt" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "drinkLogs" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        "drinkTypeID" INTEGER NOT NULL REFERENCES "drinkTypes"("id") ON DELETE CASCADE,
        "volumeMl" REAL NOT NULL,
        "loggedAt" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)
  }

  private nonisolated static func createAppSettingsTable(_ db: Database) throws {
    try #sql(
      """
      CREATE TABLE "appSettings" (
        "id" INTEGER PRIMARY KEY NOT NULL,
        "dailyGoalMl" REAL NOT NULL DEFAULT 2000,
        "unitRaw" TEXT NOT NULL DEFAULT 'metric',
        "remindersEnabled" INTEGER NOT NULL DEFAULT 0,
        "reminderIntervalMinutes" INTEGER NOT NULL DEFAULT 120,
        "quietHoursStartMinutes" INTEGER,
        "quietHoursEndMinutes" INTEGER
      ) STRICT
      """
    )
    .execute(db)
  }

  private nonisolated static func seedIfNeeded(_ db: Database) throws {
    let settingsCount =
      try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM appSettings"
      ) ?? 0
    if settingsCount == 0 {
      _ = try AppSettings.insert {
        AppSettings.Draft(
          id: 1,
          dailyGoalMl: 2000,
          unitRaw: VolumeUnit.metric.rawValue,
          remindersEnabled: false,
          reminderIntervalMinutes: 120,
          quietHoursStartMinutes: 22 * 60,
          quietHoursEndMinutes: 7 * 60
        )
      }
      .execute(db)
    }

    let typeCount =
      try Int.fetchOne(
        db,
        sql: "SELECT COUNT(*) FROM drinkTypes"
      ) ?? 0
    if typeCount == 0 {
      let now = Date()
      let defaults: [(String, String, String, Int)] = [
        ("Water", "drop.fill", "#38BDF8", 0),
        ("Tea", "cup.and.saucer.fill", "#86EFAC", 1),
        ("Coffee", "mug.fill", "#A16207", 2),
        ("Milk", "takeoutbag.and.cup.and.straw.fill", "#7C9CBF", 3),
        ("Juice", "wineglass.fill", "#FB923C", 4),
        ("Soda", "bubbles.and.sparkles.fill", "#F472B6", 5),
      ]
      for (name, icon, hex, order) in defaults {
        _ = try DrinkType.insert {
          DrinkType.Draft(
            name: name,
            iconName: icon,
            tintHex: hex,
            sortOrder: order,
            createdAt: now
          )
        }
        .execute(db)
      }
    }
  }
}
