//
//  PlaceLookupView.swift
//  LocationAndPlaceLookup
//
//  Created by Eno Yoo on 11/10/25.
//

import SwiftUI
import MapKit

struct PlaceLookupView: View {
    let locationManager: LocationManager
    @Binding var selectedPlace: Place?
    @State var placeVM = PlaceViewModel()
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var searchRegion = MKCoordinateRegion()
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "mappin.slash")
                } else {
                    List(placeVM.places) { place in
                        VStack(alignment: .leading) {
                            Text(place.name)
                                .font(.title2)
                            Text(place.address)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .onTapGesture {
                            selectedPlace = place
                            dismiss()
                        }
                        
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Location Search")
            .navigationBarTitleDisplayMode(.inline)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }

        }
        .searchable(text: $searchText)
        .autocorrectionDisabled()
        .onAppear {
            searchRegion = locationManager.getRegionAroundCurrentLocation() ?? MKCoordinateRegion()
        }
        .onDisappear {
            searchTask?.cancel()
        }
        .onChange(of: searchText) {oldValue, newValue in
            searchTask?.cancel() // stop any existing Tasks that haven't been completed
            // if search string is empty, clear out the list
            guard !newValue.isEmpty else {
                placeVM.places.removeAll()
                return
            }
            // create new search task
            searchTask = Task {
                do {
                    // wait 300ms before running current task. any typing before the task has run cancels the old task. this prevents searches from happening quickly if a user types fast, and will reduce chances that apple cuts off search because too many searches execute too quickly
                    try await Task.sleep(for: .milliseconds(300))
                    // check if task was called during sleep - if so, return & wait for new task to run or more typing to happen
                    if Task.isCancelled { return }
                    // verify search text hasn't changed during delay
                    if searchText == newValue {
                        try await placeVM.search(text: newValue, region: searchRegion)
                    }
                } catch {
                    if !Task.isCancelled {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        
    }
}

#Preview {
    PlaceLookupView(locationManager: LocationManager(), selectedPlace: .constant(Place(mapItem: MKMapItem())))
}
