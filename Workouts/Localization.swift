//
//  Localization.swift
//  Workouts
//
//  Created by Axel Rivera on 8/26/22.
//

import Foundation

typealias ActionStrings = Localization.Actions
typealias LabelStrings = Localization.Labels

typealias WorkoutStrings = Localization.Workouts
typealias CalendarStrings = Localization.Calendar
typealias ProgressStrings = Localization.Progress
typealias DashboardStrings = Localization.Dashboard
typealias TagStrings = Localization.Tags
typealias HeartRateStrings = Localization.HeartRate

struct Localization {}

extension Localization {
    
    struct Actions {
        static let ok = NSLocalizedString("Ok", comment: "Action")
        static let cancel = NSLocalizedString("Cancel", comment: "Action")
        static let done = NSLocalizedString("Done", comment: "Action")
        static let edit = NSLocalizedString("Edit", comment: "Action")
        static let save = NSLocalizedString("Save", comment: "Action")
        static let archive = NSLocalizedString("Archive", comment: "Action")
        static let reset = NSLocalizedString("Reset", comment: "Action")
        static let discard = NSLocalizedString("Discard", comment: "Action")
        static let `import` = NSLocalizedString("Import", comment: "Action")
        static let showMore = NSLocalizedString("Show More", comment: "Action")
        static let details = NSLocalizedString("Details", comment: "Action")
        static let close = NSLocalizedString("Close", comment: "Action")
        static let share = NSLocalizedString("Share", comment: "Action")
        static let delete = NSLocalizedString("Delete", comment: "Action")
        static let `continue` = NSLocalizedString("Continue", comment: "Action")
        static let `default` = NSLocalizedString("Default", comment: "Action toggle")
        static let restore = NSLocalizedString("Restore", comment: "Action")
        static let next = NSLocalizedString("Next", comment: "Action")
        
        // Feed
        static let favorite = NSLocalizedString("Favorite", comment: "Action")
        static let unfavorite = NSLocalizedString("Unfavorite", comment: "Action")
        
        static let resetFilter = NSLocalizedString("Reset Filter", comment: "Action")
        static let favoriteAll = NSLocalizedString("Favorite All", comment: "Action")
        static let unfavoriteAll = NSLocalizedString("Unfavorite All", comment: "Action")
        static let tagAll = NSLocalizedString("Tag All", comment: "Action")
        
        static let newTag = NSLocalizedString("New Tag", comment: "Action")
        static let addTags = NSLocalizedString("Add Tags", comment: "Action")
        
        static let editHeartRate = NSLocalizedString("Edit Heart Rate", comment: "Action")
        static let editHeartRateZones = NSLocalizedString("Edit Heart Rate Zones", comment: "Action")
        
        static let editTag = NSLocalizedString("Edit Tag", comment: "Action")
        static let resetAllTags = NSLocalizedString("Reset All Tags", comment: "Action")
        static let resetAll = NSLocalizedString("Reset All", comment: "Action")
        
        static let addPhoto = NSLocalizedString("Add Photo", comment: "Action")
        static let addBackgroundPhoto = NSLocalizedString("Add Background Photo", comment: "Action")
        static let openCamera = NSLocalizedString("Open Camera", comment: "Action")
        static let choosePhoto = NSLocalizedString("Choose Photo", comment: "Action")
        
        static let editZones = NSLocalizedString("Edit Zones", comment: "Action")
    }
    
    struct Labels {
        static let workout = NSLocalizedString("Workout", comment: "Label")
        static let workouts = NSLocalizedString("Workouts", comment: "Label")
        static let allWorkouts = NSLocalizedString("All Workouts", comment: "Label")
        static let noWorkouts = NSLocalizedString("No Workouts", comment: "Label")
                
        // General
        static let speed = NSLocalizedString("Speed", comment: "Label")
        static let heartRate = NSLocalizedString("Heart Rate", comment: "Label")
        static let heartRateZones = NSLocalizedString("Heart Rate Zones", comment: "Label")
        static let cadence = NSLocalizedString("Cadence", comment: "Label")
        static let elevation = NSLocalizedString("Elevation", comment: "Label")
        
        // Details
        static let analysis = NSLocalizedString("Analysis", comment: "Action")
        static let splits = NSLocalizedString("Splits", comment: "Workout action and screen title")
        static let distance = NSLocalizedString("Distance", comment: "Workout label")
        static let movingTime = NSLocalizedString("Moving Time", comment: "Workout label")
        static let totalTime = NSLocalizedString("Total Time", comment: "Workout label")
        static let pausedTime = NSLocalizedString("Paused Time", comment: "Workout label")
        static let avgSpeed = NSLocalizedString("Avg Speed", comment: "Workout label")
        static let maxSpeed = NSLocalizedString("Max Speed", comment: "Workout label")
        static let avgPace = NSLocalizedString("Avg Pace", comment: "Workout label")
        static let avgCadence = NSLocalizedString("Avg Cadence", comment: "Workout label")
        static let maxCadence = NSLocalizedString("Max Cadence", comment: "Workout label")
        static let avgHeartRate = NSLocalizedString("Avg Heart Rate", comment: "Workout label")
        static let maxHeartRate = NSLocalizedString("Max Heart Rate", comment: "Workout label")
        static let trainingLoad = NSLocalizedString("Training Load", comment: "Workout label")
        static let heartRateReserve = NSLocalizedString("Heart Rate Reserve", comment: "Workout label")
        static let source = NSLocalizedString("Source", comment: "Workout label")
        static let device = NSLocalizedString("Device", comment: "Label")
        static let elevationGain = NSLocalizedString("Elevation Gain", comment: "Workout label")
        static let elevationLoss = NSLocalizedString("Elevation Loss", comment: "Workout label")
        static let calories = NSLocalizedString("Calories", comment: "Workout label")
        static let pace = NSLocalizedString("Pace", comment: "Workout label")
        static let best = NSLocalizedString("Best", comment: "Label")
        
        static let filter = NSLocalizedString("Filter", comment: "Label")
        static let date = NSLocalizedString("Date", comment: "Label")
        static let favorites = NSLocalizedString("Favorites", comment: "Label")
        static let dateRange = NSLocalizedString("Date Range", comment: "Label")
        
        static let total = NSLocalizedString("Total", comment: "Label")
        static let average = NSLocalizedString("Average", comment: "Label")
        static let time = NSLocalizedString("Time", comment: "Label")
        
        static let min = NSLocalizedString("Min", comment: "Label")
        static let minimum = NSLocalizedString("Minimum", comment: "Label")
        
        static let max = NSLocalizedString("Max", comment: "Label")
        static let maximum = NSLocalizedString("Maximum", comment: "Label")
        
        static let location = NSLocalizedString("Location", comment: "Label")
        static let indoor = NSLocalizedString("Indoor", comment: "Label")
        static let outdoor = NSLocalizedString("Outdoor", comment: "Label")
        
        static let dayOfWeek = NSLocalizedString("Day of Week", comment: "Label")
        static let weekday = NSLocalizedString("Weekday", comment: "Label")
        static let weekend = NSLocalizedString("Weekend", comment: "Label")
        
        static let tag = NSLocalizedString("Tag", comment: "Label singular")
        static let tags = NSLocalizedString("Tags", comment: "Label plural")
        
        static let sortBy = NSLocalizedString("Sort By", comment: "Label")
        static let duration = NSLocalizedString("Duration", comment: "Label")
        
        static let active = NSLocalizedString("Active", comment: "Label")
        static let archived = NSLocalizedString("Archived", comment: "Label")
        
        static let loadingCapitalized = NSLocalizedString("LOADING", comment: "Label capitalized")
        
        static let imageMissing = NSLocalizedString("Image Missing", comment: "Label")
        static let confirmation = NSLocalizedString("Confirmation", comment: "Label")
        
        static let name = NSLocalizedString("Name", comment: "Label")
        
        static let start = NSLocalizedString("Start", comment: "Label")
        static let end = NSLocalizedString("End", comment: "Label")
        
        // Heart Rate
        static let restingHeartRate = NSLocalizedString("Reseting Heart Rate", comment: "Label")
        static let bpm = NSLocalizedString("bpm", comment: "Heart rate bpm unit")
                
        // Activities
        static let ride = NSLocalizedString("Ride", comment: "Label singular")
        static let rides = NSLocalizedString("Rides", comment: "Label plural")
        static let run = NSLocalizedString("Run", comment: "Label singular")
        static let runs = NSLocalizedString("Runs", comment: "Label plural")
        static let walk = NSLocalizedString("Walk", comment: "Label singular")
        static let walks = NSLocalizedString("Walks", comment: "Label plural")
        static let hikes = NSLocalizedString("Hikes", comment: "Label")
        
        // Gender
        static let male = NSLocalizedString("Male", comment: "Label")
        static let female = NSLocalizedString("Female", comment: "Label")
        static let notAvailable = NSLocalizedString("Not Available", comment: "Label")
        
        // Dashboard
        static let noMetrics = NSLocalizedString("No Metrics", comment: "Label")
        static let workoutSummary = NSLocalizedString("Workout Summary", comment: "Label")
        
        static let noDataAvailable = NSLocalizedString("No Data Available", comment: "Label")
        static let display = NSLocalizedString("Display", comment: "Label")
        
        static let selectYear = NSLocalizedString("Select Year", comment: "Label")
        
        static let day = NSLocalizedString("Day", comment: "Label")
        static let week = NSLocalizedString("Week", comment: "Label")
        static let month = NSLocalizedString("Month", comment: "Label")
        static let year = NSLocalizedString("Year", comment: "Label")
        static let since = NSLocalizedString("Since", comment: "Label")
        
        static let intervals = NSLocalizedString("Intervals", comment: "Label")
        static let dates = NSLocalizedString("Dates", comment: "Label")
        static let selectTimeframe = NSLocalizedString("Select Timeframe", comment: "Label")
        static let metrics = NSLocalizedString("Metrics", comment: "Label")
        static let supportedMetrics = NSLocalizedString("Supported Metrics", comment: "Label")
        
        // Tags
        static let state = NSLocalizedString("State", comment: "Label")
        static let noTags = NSLocalizedString("No Tags", comment: "Label")
        static let noArchivedTags = NSLocalizedString("No Archived Tags", comment: "Label")
        
        static let activeTags = NSLocalizedString("Active Tags", comment: "Label")
        static let archivedTags = NSLocalizedString("Archived Tags", comment: "Label")
        static let resetTags = NSLocalizedString("Reset Tags", comment: "Label")
        static let tagName = NSLocalizedString("Tag Name", comment: "Label")
        static let gearType = NSLocalizedString("Gear Type", comment: "Label")
        
        // Sharing
        static let style = NSLocalizedString("Style", comment: "Label")
        static let noPhoto = NSLocalizedString("No Photo", comment: "Label")
        static let details = NSLocalizedString("Details", comment: "Label")
        
        static let selectMapColor = NSLocalizedString("Select Map Color", comment: "Label")
        static let dark = NSLocalizedString("Dark", comment: "Label")
        static let light = NSLocalizedString("Light", comment: "Label")
        static let selectFilter = NSLocalizedString("Select Filter", comment: "Label")
        
        static let `default` = NSLocalizedString("Default", comment: "Label")
    }
    
    struct Content {
        static let workoutsTab = NSLocalizedString("Workouts", comment: "Main Tab")
        static let calendarTab = NSLocalizedString("Calendar", comment: "Main Tab")
        static let progressTab = NSLocalizedString("Progress", comment: "Main Tab")
        static let dashboardTab = NSLocalizedString("Dashboard", comment: "Main Tab")
        static let tagsTab = NSLocalizedString("Tags", comment: "Main Tab")
    }
    
    struct Workouts {
        static let workoutsCount = NSLocalizedString("%@ Workouts", comment: "Workouts count [count]")
        
        static func workoutCount(for total: Int) -> String {
            String(format: workoutsCount, total.formatted())
        }
        
        static let resultsCount = NSLocalizedString("%@ Results", comment: "Results count [count]")
        
        static func resultsCount(for total: Int) -> String {
            String(format: resultsCount, total.formatted())
        }
        
        static var lapNumber = NSLocalizedString("Lap %@", comment: "Lab number [number]")
        
        static func lapNumber(_ number: Int) -> String {
            String(format: lapNumber, number.formatted())
        }
        
        static let errorTitle = NSLocalizedString("Workout Error", comment: "Alert title")
        static let errorMessageFavoriteStatus = NSLocalizedString("Unable to update favorite status.", comment: "Alert message")
    }
    
    struct WorkoutImport {
        // Status
        
        static let statusNew = NSLocalizedString("New Workout", comment: "Import status")
        static let statusDuplicate = NSLocalizedString("Duplicate Workout", comment: "Import status")
        static let statusProcessing = NSLocalizedString("Processing…", comment: "Import status")
        static let statusProcessed = NSLocalizedString("Import Complete", comment: "Import status")
        static let statusNotSupported = NSLocalizedString("Sport Not Supported", comment: "Import status")
        static let statusFailed = NSLocalizedString("Import Failed", comment: "Import status")
        static let statusInvalid = NSLocalizedString("Invalid File", comment: "Import status")
        static let statusEmpty = NSLocalizedString("Missing Workout", comment: "Import status")
    }
    
    struct HeartRateZones {
        static let recovery = NSLocalizedString("Recovery", comment: "HR Zone label")
        static let aerobic = NSLocalizedString("Aerobic", comment: "HR Zone label")
        static let tempo = NSLocalizedString("Tempo", comment: "HR Zone label")
        static let threshold = NSLocalizedString("Threshold", comment: "HR Zone label")
        static let anaerobic = NSLocalizedString("Anaerobic", comment: "HR Zone label")
    }
    
    struct Calendar {
        // Date Filter
        static let lastTwelveMonths = NSLocalizedString("Last 12 Months", comment: "Calendar date filter")
        static let lastFiveYears = NSLocalizedString("Last 5 Years", comment: "Calendar date filter")
        static let byYear = NSLocalizedString("By Year", comment: "Calendar date filter")
    }
    
    struct Progress {
        static let yearToDate = NSLocalizedString("Year to Date", comment: "Label")
        static let allTime = NSLocalizedString("All Time", comment: "Label")
        static let perWeek = NSLocalizedString("/week", comment: "Describes times per week in progress")
        static let perMonth = NSLocalizedString("/month", comment: "Describes times per month in progress")
        
        static let lastTwelveWeeks = NSLocalizedString("Last 12 Weeks", comment: "Label")
        static let lastTwelveMonths = NSLocalizedString("Last 12 Months", comment: "Label")
        
        static let byMonth = NSLocalizedString("By Month", comment: "Label")
        static let byWeek = NSLocalizedString("By Week", comment: "Label")
        
        static let currentWeek = NSLocalizedString("Current Week", comment: "Label")
        static let currentMonth = NSLocalizedString("Current Month", comment: "Label")
    }
    
    struct Dashboard {
        static let today = NSLocalizedString("Today", comment: "Dashboard interval")
        static let yesterday = NSLocalizedString("Yesterday", comment: "Dashboard interval")
        static let currentWeek = NSLocalizedString("Current Week", comment: "Dashboard interval")
        static let lastWeek = NSLocalizedString("Last Week", comment: "Dashboard interval")
        static let currentMonth = NSLocalizedString("Current Month", comment: "Dashboard interval")
        static let lastMonth = NSLocalizedString("Last Month", comment: "Dashboard interval")
        static let currentYear = NSLocalizedString("Current Year", comment: "Dashboard interval")
        static let lastYear = NSLocalizedString("Last Year", comment: "Dashboard interval")
        static let allTime = NSLocalizedString("All Time", comment: "Dashboard interval")
        static let dates = NSLocalizedString("Dates", comment: "Dashboard interval")
        
        static let dailyStats = NSLocalizedString("Daily Stats", comment: "Dashboard share label")
        static let weeklyStats = NSLocalizedString("Weekly Stats", comment: "Dashboard share label")
        static let monthlyStats = NSLocalizedString("Monthly Stats", comment: "Dashboard share label")
        static let yearlyStats = NSLocalizedString("Yearly Stats", comment: "Dashboard share label")
        static let fitnessStats = NSLocalizedString("Fitness Stats", comment: "Dashboard share label")
        static let allTimeStats = NSLocalizedString("All Time Stats", comment: "Dashboard share label")
        
        static let topWorkouts = NSLocalizedString("TOP WORKOUTS", comment: "Dashboard card")
        
        static let metricsDescription = NSLocalizedString(
            "Dashboard metrics help you get a better picture of your fitness stats by displaying additional data stored in the Health app on your iPhone.",
            comment: "Dashboard metrics description"
        )
    }
    
    struct Tags {
        static let deletedTagsCannotBeRestored = NSLocalizedString("Deleted tags cannot be restored.", comment: "Message telling user that deleted tags cannot be restored")
        
        // New Screen
        static let gearTypeCannotBeEdited = NSLocalizedString("Gear type cannot be edited later.", comment: "Tell user gear types cannot be edited at later time")
        static let defaultNoneFooter = NSLocalizedString("Default tags will be applied to all new workouts.", comment: "Default message when NONE gear selected")
        static let defaultGearFooter = NSLocalizedString("Default tags will be applied to new workouts based on gear type.", comment: "Default message when gear selected")
        
        // Reset Screen
        static let resetAllTagsFooter = NSLocalizedString("Clears all tag assignments for all workouts.", comment: "Message telling user all tag assignements will be deleted")
        
        static let areYouSureTitle = NSLocalizedString("Are You Sure?", comment: "Alert title asking user if he wants to continue")
        
        static let allResetConfirmationMessage = NSLocalizedString(
            "Do you want to reset tag assignements for all workouts? This will clear tags for all existing workouts and cannot be undone.",
            comment: "Tells user to confirm that all tag assignments will be deleted"
        )
        
        static let singleResetConfirmationMessage = NSLocalizedString(
            "Do you want to reset tag %@ from all workouts? This will clear tag %@ from workouts using it and cannot be undone.",
            comment: "Tells user to confirm that a single tag will be deleted from workouts."
        )
        
        // Errors
        static let errorTitle = NSLocalizedString("Tag Error", comment: "Error title")
        static let errorProcessingMessage = NSLocalizedString("Error processing action.", comment: "Process tag error message")
        static let errorDeleteMessage = NSLocalizedString("Error deleting tag.", comment: "Delete tag error message")
        
        static let errorUnableArchiveMessage = NSLocalizedString("Unable to archive tag.", comment: "Archive tag error message")
        static let errorUnableRestoreMessage = NSLocalizedString("Unable to restore tag.", comment: "Restore tag error message")
        static let errorUnableDeleteMessage = NSLocalizedString("Unable to delete tag.", comment: "Delete tag error message")
        
        // Empty Tags
        static let emptyTagsMessage = NSLocalizedString("Looks like you don't have any tags yet.", comment: "Message for empty tags")
        static let emptyTagsSelectorMessage = NSLocalizedString("Looks like you don't have any tags yet. Add some default values or create your own.", comment: "Message for empty tags in selector screen")
        static let addDefaultTags = NSLocalizedString("Add Default Tags", comment: "Action")
        
        // Apply All
        static let applyAllTitle = NSLocalizedString("Apply Tags", comment: "Alert title")
        static let applyConfirmationMessage = NSLocalizedString("Apply tags to all %@ results in filter? Some tags may be ignored based on gear type.", comment: "Alert message for tag confirmation [tag count]")
        
        static func singleResetConfirmationMessage(for tagName: String) -> String {
            String(format: singleResetConfirmationMessage, tagName, tagName)
        }
        
        static func applyConfirmationMessage(tagCount: Int) -> String {
            String(format: applyConfirmationMessage, tagCount.formatted())
        }
        
        // Selector
        static let updateErrorTitle = NSLocalizedString("Update Error", comment: "Alert title (update tag error)")
        static let updateErrorMessage = NSLocalizedString("Unable to update tag %@.", comment: "Alert message (update tag error [tag name]")
        
        static func updateErrorMessage(name: String) -> String {
            String(format: updateErrorMessage, name)
        }
        
        // Restore
        
        static let restoreMessage = NSLocalizedString("%@ - Restored %@", comment: "Restored tag message. [name], [date]")
        
        static func restoreMessage(name: String, date: Date) -> String {
            String(
                format: restoreMessage,
                name,
                date.formatted(date: .numeric, time: .standard)
            )
        }
    }
    
    struct HeartRate {
        // Edit Heart Rate
        
        static let useFormula = NSLocalizedString("Use Formula", comment: "Calculate max heart rate using formula label")
        static let useRecentValue = NSLocalizedString("Use Recent Value", comment: "Toggle action for using resting heart rate")
                
        // Zones
        
        static let zone1Label = NSLocalizedString("Zone 1", comment: "Zone 1 label")
        static let zone2Label = NSLocalizedString("Zone 2", comment: "Zone 2 label")
        static let zone3Label = NSLocalizedString("Zone 3", comment: "Zone 3 label")
        static let zone4Label = NSLocalizedString("Zone 4", comment: "Zone 4 label")
        static let zone5Label = NSLocalizedString("Zone 5", comment: "Zone 5 label")
        
        static let zone1Name = NSLocalizedString("Recovery", comment: "Zone 1 name")
        static let zone2Name = NSLocalizedString("Aerobic", comment: "Zone 2 name")
        static let zone3Name = NSLocalizedString("Tempo", comment: "Zone 3 name")
        static let zone4Name = NSLocalizedString("Threshold", comment: "Zone 4 name")
        static let zone5Name = NSLocalizedString("Anaerobic", comment: "Zone 5 name")
        
        static let zone1PercentLabel = NSLocalizedString("50 - 60% of HR max", comment: "Zone 1 Percent Label")
        static let zone2PercentLabel = NSLocalizedString("60 - 70% of HR max", comment: "Zone 2 Percent Label")
        static let zone3PercentLabel = NSLocalizedString("70 - 80% of HR max", comment: "Zone 3 Percent Label")
        static let zone4PercentLabel = NSLocalizedString("80 - 90% of HR max", comment: "Zone 4 Percent Label")
        static let zone5PercentLabel = NSLocalizedString("90 - 100% of HR max", comment: "Zone 5 Percent Label")
        
        static let zone1Explanation = NSLocalizedString(
            "Zone 1 is used to get your body moving at a relaxed, easy pace. This zone can be used during a brisk walk, easy training day, warming up or cooling down.",
            comment: "Zone 1 Explanation"
        )
        
        static let zone2Explanation = NSLocalizedString(
            "Training in Zone 2 is used for longer training sessions. You can sustain a comfortable pace for many miles, yet still hold a conversation with your workout partner. Light or slow jogging falls info Zone 2.",
            comment: "Zone 2 Explanation"
        )
        
        static let zone3Explanation = NSLocalizedString(
            "Zone 3 training is where you push the pace to build up speed and strength and it’s more difficult to hold a conversation. Easy running falls into Zone 3.",
            comment: "Zone 3 Explanation"
        )
        
        static let zone4Explanation = NSLocalizedString(
            "In Zone 4 you’re breathing hard and moving fast at an uncomfortable pace. Your body is processing lactic acid as a fuel source; beyond this level, lactic acid builds too fast and fatigues muscles. Fast running falls info Zone 4.",
            comment: "Zone 4 Explanation"
        )
        
        static let zone5Explanation = NSLocalizedString(
            "In Zone 5 you’re at maximum effort. Your heart and lungs will be working at their maximum capacity. Lactic acid will build up in your blood and it will be difficult to sustain your pace for long. Sprints fall into Zone 5.",
            comment: "Zone 5 Explanation"
        )
                
    }
    
}
