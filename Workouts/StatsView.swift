//
//  StatsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/16/21.
//

import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20.0) {
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("Jan 18 - Jan 24")
                            .font(.title3)
                        
                        HStack(spacing: 10.0) {
                            VStack(alignment: .leading, spacing: 5.0) {
                                Text("Distance")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("100.0 mi")
                                    .font(.callout)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 5.0) {
                                Text("Time")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("4h 48m")
                                    .font(.callout)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 5.0) {
                                Text("Elevation")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("1,000 ft")
                                    .font(.callout)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 5.0) {
                                Text("Calories")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("1,000 cal")
                                    .font(.callout)
                            }
                            
                        }
                        .padding([.top, .bottom], 10.0)
                        
                        Text("Last 12 Weeks")
                            .font(.headline)
                        
                        Text("Chart Goes Here")
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: 200.0)
                            .background(Color.divider)
                    }
                    
                    VStack(alignment: .leading, spacing: 10.0) {
                        StatsRow(text: "Avg Rides/Week", detail: "3")
                        StatsRow(text: "Avg Time/Week", detail: "4h 30m")
                        StatsRow(text: "Avg Distance/Week", detail: "60 mi")
                        StatsRow(text: "Avg Calories/Week", detail: "100 ft")
                    }
                    
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("Current Month")
                            .font(.title3)
                            .padding(.bottom, 5.0)
                        
                        StatsRow(text: "Rides", detail: "3")
                        StatsRow(text: "Time", detail: "4h 30m")
                        StatsRow(text: "Distance", detail: "60 mi")
                        StatsRow(text: "Elevation Gain", detail: "100 ft")
                    }
                    
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("Current Year")
                            .font(.title3)
                            .padding(.bottom, 5.0)
                        
                        StatsRow(text: "Rides", detail: "3")
                        StatsRow(text: "Time", detail: "4h 30m")
                        StatsRow(text: "Distance", detail: "60 mi")
                        StatsRow(text: "Elevation Gain", detail: "100 ft")
                    }
                    
                    VStack(alignment: .leading, spacing: 10.0) {
                        Text("All Time")
                            .font(.title3)
                            .padding(.bottom, 5.0)
                        
                        StatsRow(text: "Rides", detail: "3")
                        StatsRow(text: "Time", detail: "4h 30m")
                        StatsRow(text: "Distance", detail: "60 mi")
                        StatsRow(text: "Elevation Gain", detail: "100 ft")
                        StatsRow(text: "Longest Ride", detail: "60 mi")
                        StatsRow(text: "Highest Climb", detail: "100 ft", last: true)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {}, label: {
                            Text("Outdoor ")
                        })
                        Button(action: {}, label: {
                            Text("Running")
                        })
                    } label: {
                        Text("Cycling")
                    }
                }
            }
        }
    }
}

struct StatsRow: View {
    
    var text: String
    var detail: String
    var last = false
    
    var body: some View {
        HStack {
            Text(text)
                .foregroundColor(.secondary)
            Spacer()
            Text(detail)
        }
        .font(.callout)
        
        if !last {
            Divider()
        }
    }
    
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
    }
}
