//
//  ContentView.swift
//  LocationAndPlaceLookup
//
//  Created by Eno Yoo on 11/10/25.
//

import SwiftUI
internal import _LocationEssentials

struct ContentView: View {
    @State var locationManager = LocationManager()
    @State var selectedPlace: Place?
    @State private var sheetIsPresented = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(selectedPlace?.name ?? "n/a")
                    .font(.title2)
                Text(selectedPlace?.address ?? "n/a")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text("\(selectedPlace?.latitude ?? 0.0), \(selectedPlace?.longitude ?? 0.0)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                sheetIsPresented.toggle()
            } label: {
                Image(systemName: "location.magnifyingglass")
                Text("Location Search")
            }
            .buttonStyle(.glassProminent)

        }
        .padding()
        .task {
            // get user location once view appears
            // handle case when user already authorized location use
            if let location = locationManager.location {
                selectedPlace = await Place(location: location)
            }
            //setup a location callback: this handles when location comes in after the app launches - it will catch the first locationUpdate (which is what we need, otherwise we wont see info in the VStack update after the first user authorizes location use)
            locationManager.locationUpdated = { location in
                // we now know we have a new location, so use it to update selectedPlace
                Task {
                    selectedPlace = await Place(location: location)
                }
            }
            
        }
        .sheet(isPresented: $sheetIsPresented) {
            PlaceLookupView(locationManager: locationManager, selectedPlace: $selectedPlace)
        }
    }
}

#Preview {
    ContentView()
}
