//
//  HKWorkoutActivityType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 2/26/21.
//

import HealthKit
import SwiftUI

extension HKWorkoutActivityType {
    
    static let indoorOutdoorList: [HKWorkoutActivityType] = [.running, .cycling, .walking]

    var name: String {
        switch self {
        case .americanFootball:             return NSLocalizedString("American Football", comment: "Sport")
        case .archery:                      return NSLocalizedString("Archery", comment: "Sport")
        case .australianFootball:           return NSLocalizedString( "Australian Football", comment: "Sport")
        case .badminton:                    return NSLocalizedString("Badminton", comment: "Sport")
        case .baseball:                     return NSLocalizedString("Baseball", comment: "Sport")
        case .basketball:                   return NSLocalizedString("Basketball", comment: "Sport")
        case .bowling:                      return NSLocalizedString("Bowling", comment: "Sport")
        case .boxing:                       return NSLocalizedString("Boxing", comment: "Sport")
        case .climbing:                     return NSLocalizedString("Climbing", comment: "Sport")
        case .crossTraining:                return NSLocalizedString("Cross Training", comment: "Sport")
        case .curling:                      return NSLocalizedString("Curling", comment: "Sport")
        case .cycling:                      return NSLocalizedString("Cycling", comment: "Sport")
        case .dance:                        return NSLocalizedString("Dance", comment: "Sport")
        case .danceInspiredTraining:        return NSLocalizedString("Dance Inspired Training", comment: "Sport")
        case .elliptical:                   return NSLocalizedString("Elliptical", comment: "Sport")
        case .equestrianSports:             return NSLocalizedString("Equestrian Sports", comment: "Sport")
        case .fencing:                      return NSLocalizedString("Fencing", comment: "Sport")
        case .fishing:                      return NSLocalizedString("Fishing", comment: "Sport")
        case .functionalStrengthTraining:   return NSLocalizedString("Functional Strength Training", comment: "Sport")
        case .golf:                         return NSLocalizedString("Golf", comment: "Sport")
        case .gymnastics:                   return NSLocalizedString("Gymnastics", comment: "Sport")
        case .handball:                     return NSLocalizedString("Handball", comment: "Sport")
        case .hiking:                       return NSLocalizedString("Hiking", comment: "Sport")
        case .hockey:                       return NSLocalizedString("Hockey", comment: "Sport")
        case .hunting:                      return NSLocalizedString("Hunting", comment: "Sport")
        case .lacrosse:                     return NSLocalizedString("Lacrosse", comment: "Sport")
        case .martialArts:                  return NSLocalizedString("Martial Arts", comment: "Sport")
        case .mindAndBody:                  return NSLocalizedString("Mind and Body", comment: "Sport")
        case .mixedMetabolicCardioTraining: return NSLocalizedString("Mixed Metabolic Cardio Training", comment: "Sport")
        case .paddleSports:                 return NSLocalizedString("Paddle Sports", comment: "Sport")
        case .play:                         return NSLocalizedString("Play", comment: "Sport")
        case .preparationAndRecovery:       return NSLocalizedString("Preparation and Recovery", comment: "Sport")
        case .racquetball:                  return NSLocalizedString("Racquetball", comment: "Sport")
        case .rowing:                       return NSLocalizedString("Rowing", comment: "Sport")
        case .rugby:                        return NSLocalizedString("Rugby", comment: "Sport")
        case .running:                      return NSLocalizedString("Running", comment: "Sport")
        case .sailing:                      return NSLocalizedString("Sailing", comment: "Sport")
        case .skatingSports:                return NSLocalizedString("Skating Sports", comment: "Sport")
        case .snowSports:                   return NSLocalizedString("Snow Sports", comment: "Sport")
        case .soccer:                       return NSLocalizedString("Soccer", comment: "Sport")
        case .softball:                     return NSLocalizedString("Softball", comment: "Sport")
        case .squash:                       return NSLocalizedString("Squash", comment: "Sport")
        case .stairClimbing:                return NSLocalizedString("Stair Climbing", comment: "Sport")
        case .surfingSports:                return NSLocalizedString("Surfing Sports", comment: "Sport")
        case .swimming:                     return NSLocalizedString("Swimming", comment: "Sport")
        case .tableTennis:                  return NSLocalizedString("Table Tennis", comment: "Sport")
        case .tennis:                       return NSLocalizedString("Tennis", comment: "Sport")
        case .trackAndField:                return NSLocalizedString("Track and Field", comment: "Sport")
        case .traditionalStrengthTraining:  return NSLocalizedString("Strength Training", comment: "Sport")
        case .volleyball:                   return NSLocalizedString("Volleyball", comment: "Sport")
        case .walking:                      return NSLocalizedString("Walking", comment: "Sport")
        case .waterFitness:                 return NSLocalizedString("Water Fitness", comment: "Sport")
        case .waterPolo:                    return NSLocalizedString("Water Polo", comment: "Sport")
        case .waterSports:                  return NSLocalizedString("Water Sports", comment: "Sport")
        case .wrestling:                    return NSLocalizedString("Wrestling", comment: "Sport")
        case .yoga:                         return NSLocalizedString("Yoga", comment: "Sport")

        // iOS 10
        case .barre:                        return NSLocalizedString("Barre", comment: "Sport")
        case .coreTraining:                 return NSLocalizedString("Core Training", comment: "Sport")
        case .crossCountrySkiing:           return NSLocalizedString("Cross Country Skiing", comment: "Sport")
        case .downhillSkiing:               return NSLocalizedString("Downhill Skiing", comment: "Sport")
        case .flexibility:                  return NSLocalizedString("Flexibility", comment: "Sport")
        case .highIntensityIntervalTraining:    return NSLocalizedString("HIIT", comment: "Sport")
        case .jumpRope:                     return NSLocalizedString("Jump Rope", comment: "Sport")
        case .kickboxing:                   return NSLocalizedString("Kickboxing", comment: "Sport")
        case .pilates:                      return NSLocalizedString("Pilates", comment: "Sport")
        case .snowboarding:                 return NSLocalizedString("Snowboarding", comment: "Sport")
        case .stairs:                       return NSLocalizedString("Stairs", comment: "Sport")
        case .stepTraining:                 return NSLocalizedString("Step Training", comment: "Sport")
        case .wheelchairWalkPace:           return NSLocalizedString("Wheelchair Walk Pace", comment: "Sport")
        case .wheelchairRunPace:            return NSLocalizedString("Wheelchair Run Pace", comment: "Sport")

        // iOS 11
        case .taiChi:                       return NSLocalizedString("Tai Chi", comment: "Sport")
        case .mixedCardio:                  return NSLocalizedString("Mixed Cardio", comment: "Sport")
        case .handCycling:                  return NSLocalizedString("Hand Cycling", comment: "Sport")

        // iOS 13
        case .discSports:                   return NSLocalizedString("Disc Sports", comment: "Sport")
        case .fitnessGaming:                return NSLocalizedString("Fitness Gaming", comment: "Sport")
        
        // iOS 14
        case .cardioDance:                  return NSLocalizedString("Cardio Dance", comment: "Sport")
        case .socialDance:                  return NSLocalizedString("Social Dance", comment: "Sport")
        case .pickleball:                   return NSLocalizedString("Pickleball", comment: "Sport")
        case .cooldown:                     return NSLocalizedString("Cooldown", comment: "Sport")

        // Catch-all
        default:                            return NSLocalizedString("Other", comment: "Sport")
        }
    }
    
    var image: UIImage {
        switch self {
        case .americanFootball:             return UIImage.football()
        case .archery:                      return UIImage.bowArrow()
        case .australianFootball:           return UIImage.rugbyBall()
        case .badminton:                    return UIImage.badminton()
        case .baseball:                     return UIImage.baseballBatBall()
        case .basketball:                   return UIImage.basketball()
        case .bowling:                      return UIImage.bowlingBallPin()
        case .boxing:                       return UIImage.boxingGlove()
        case .climbing:                     return UIImage.mountain()
        case .crossTraining:                return UIImage.bolt()
        case .curling:                      return UIImage.curlingStone()
        case .cycling:                      return UIImage.personBiking()
        case .dance:                        return UIImage.music()
        case .danceInspiredTraining:        return UIImage.music()
        case .elliptical:                   return UIImage.bolt()
        case .equestrianSports:             return UIImage.horseSaddle()
        case .fencing:                      return UIImage.swords()
        case .fishing:                      return UIImage.fishingRod()
        case .functionalStrengthTraining:   return UIImage.dumbbell()
        case .golf:                         return UIImage.golfClub()
        case .gymnastics:                   return UIImage.medalSolid()
        case .handball:                     return UIImage.soccer()
        case .hiking:                       return UIImage.personHiking()
        case .hockey:                       return UIImage.hockeySticks()
        case .hunting:                      return UIImage.crosshairs()
        case .lacrosse:                     return UIImage.lacrosseStickBall()
        case .martialArts:                  return UIImage.uniformMartialArts()
        case .mindAndBody:                  return UIImage.spa()
        case .mixedMetabolicCardioTraining: return UIImage.personRunning()
        case .paddleSports:                 return UIImage.pickleball()
        case .play:                         return UIImage.bolt()
        case .preparationAndRecovery:       return UIImage.person()
        case .racquetball:                  return UIImage.racquet()
        case .rowing:                       return UIImage.bolt()
        case .rugby:                        return UIImage.rugbyBall()
        case .running:                      return UIImage.personRunning()
        case .sailing:                      return UIImage.sailboat()
        case .skatingSports:                return UIImage.personSkating()
        case .snowSports:                   return UIImage.personSkiingNordic()
        case .soccer:                       return UIImage.soccer()
        case .softball:                     return UIImage.baseballBatBall()
        case .squash:                       return UIImage.racquet()
        case .stairClimbing:                return UIImage.stairs()
        case .surfingSports:                return UIImage.bolt()
        case .swimming:                     return UIImage.personSwimming()
        case .tableTennis:                  return UIImage.tableTennisPaddleBall()
        case .tennis:                       return UIImage.racquet()
        case .trackAndField:                return UIImage.stopwatch20()
        case .traditionalStrengthTraining:  return UIImage.dumbbell()
        case .volleyball:                   return UIImage.volleyball()
        case .walking:                      return UIImage.personWalking()
        case .waterFitness:                 return UIImage.water()
        case .waterPolo:                    return UIImage.water()
        case .waterSports:                  return UIImage.water()
        case .wrestling:                    return UIImage.luchadorMask()
        case .yoga:                         return UIImage.spa()

        // iOS 10
        case .barre:                        return UIImage.bolt()
        case .coreTraining:                 return UIImage.person()
        case .crossCountrySkiing:           return UIImage.personSkiing()
        case .downhillSkiing:               return UIImage.personSkiing()
        case .flexibility:                  return UIImage.person()
        case .highIntensityIntervalTraining:    return UIImage.bolt()
        case .jumpRope:                     return UIImage.bolt()
        case .kickboxing:                   return UIImage.bolt()
        case .pilates:                      return UIImage.spa()
        case .snowboarding:                 return UIImage.personSnowboarding()
        case .stairs:                       return UIImage.stairs()
        case .stepTraining:                 return UIImage.stairs()
        case .wheelchairWalkPace:           return UIImage.wheelchair()
        case .wheelchairRunPace:            return UIImage.wheelchairMove()

        // iOS 11
        case .taiChi:                       return UIImage.bolt()
        case .mixedCardio:                  return UIImage.bolt()
        case .handCycling:                  return UIImage.bolt()

        // iOS 13
        case .discSports:                   return UIImage.flyingDisc()
        case .fitnessGaming:                return UIImage.headSideGoggles()
        
        // iOS 14
        case .cardioDance:                  return UIImage.music()
        case .socialDance:                  return UIImage.music()
        case .pickleball:                   return UIImage.pickleball()
        case .cooldown:                     return UIImage.person()

        // Catch-all
        default:                            return UIImage.bolt()
        }
    }
    
    static var allActivities: [HKWorkoutActivityType] = [
        .americanFootball,
        .archery,
        .australianFootball,
        .badminton,
        .baseball,
        .basketball,
        .bowling,
        .boxing,
        .climbing,
        .crossTraining,
        .curling,
        .cycling,
        .elliptical,
        .equestrianSports,
        .fencing,
        .fishing,
        .functionalStrengthTraining,
        .golf,
        .gymnastics,
        .handball,
        .hiking,
        .hockey,
        .hunting,
        .lacrosse,
        .martialArts,
        .mindAndBody,
        .paddleSports,
        .play,
        .preparationAndRecovery,
        .racquetball,
        .rowing,
        .rugby,
        .running,
        .sailing,
        .skatingSports,
        .snowSports,
        .soccer,
        .softball,
        .squash,
        .stairClimbing,
        .surfingSports,
        .swimming,
        .tableTennis,
        .tennis,
        .trackAndField,
        .traditionalStrengthTraining,
        .volleyball,
        .walking,
        .waterFitness,
        .waterPolo,
        .waterSports,
        .wrestling,
        .yoga,
        .barre,
        .coreTraining,
        .crossCountrySkiing,
        .downhillSkiing,
        .flexibility,
        .highIntensityIntervalTraining,
        .jumpRope,
        .kickboxing,
        .pilates,
        .snowboarding,
        .stairs,
        .stepTraining,
        .wheelchairWalkPace,
        .wheelchairRunPace,
        .taiChi,
        .mixedCardio,
        .handCycling,
        .discSports,
        .fitnessGaming,
        .cardioDance,
        .socialDance,
        .pickleball,
        .cooldown
    ]

}
