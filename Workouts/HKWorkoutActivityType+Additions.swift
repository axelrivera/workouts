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
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional Strength Training"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Strength Training"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"

        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "HIIT"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"

        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"

        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"
        
        // iOS 14
        case .cardioDance:                  return "Cardio Dance"
        case .socialDance:                  return "Social Dance"
        case .pickleball:                   return "Pickleball"
        case .cooldown:                     return "Cooldown"

        // Catch-all
        default:                            return "Other"
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
