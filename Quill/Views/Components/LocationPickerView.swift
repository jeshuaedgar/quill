import SwiftUI
import MapKit

struct LocationPickerView: View {
    @Binding var selectedLatitude: Double?
    @Binding var selectedLongitude: Double?
    @Binding var selectedName: String?
    @Binding var radius: Double?
    @Binding var triggerOnArrival: Bool
    
    @State private var locationManager = LocationManager.shared
    @State private var searchText = ""
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedResult: LocationResult?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search location...", text: $searchText)
                        .onSubmit {
                            locationManager.searchLocations(query: searchText)
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            locationManager.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // MARK: - Search Results
                if !locationManager.searchResults.isEmpty {
                    List(locationManager.searchResults) { result in
                        Button {
                            selectLocation(result)
                        } label: {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.red)
                                
                                VStack(alignment: .leading) {
                                    Text(result.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                if selectedResult?.id == result.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 200)
                }
                
                // MARK: - Map
                Map(position: $mapPosition) {
                    if let result = selectedResult {
                        Marker(
                            result.name,
                            coordinate: result.coordinate
                        )
                        .tint(.red)
                        
                        MapCircle(
                            center: result.coordinate,
                            radius: radius ?? 100
                        )
                        .foregroundStyle(.blue.opacity(0.15))
                        .stroke(.blue, lineWidth: 1)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // MARK: - Options
                if selectedResult != nil {
                    VStack(spacing: 12) {
                        // Trigger type
                        Picker("Trigger", selection: $triggerOnArrival) {
                            Label("On Arrival", systemImage: "figure.walk.arrival")
                                .tag(true)
                            Label("On Departure", systemImage: "figure.walk.departure")
                                .tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        // Radius
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Radius: \(Int(radius ?? 100))m")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { radius ?? 100 },
                                    set: { radius = $0 }
                                ),
                                in: 50...500,
                                step: 50
                            )
                        }
                        
                        // Confirm Button
                        Button {
                            confirmSelection()
                        } label: {
                            Text("Set Location")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if selectedLatitude != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Remove", role: .destructive) {
                            selectedLatitude = nil
                            selectedLongitude = nil
                            selectedName = nil
                            radius = nil
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if !locationManager.isAuthorized {
                    locationManager.requestPermission()
                }
                locationManager.requestLocation()
            }
        }
    }
    
    // MARK: - Actions
    
    private func selectLocation(_ result: LocationResult) {
        selectedResult = result
        
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(
                center: result.coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            ))
        }
        
        HapticManager.shared.selection()
    }
    
    private func confirmSelection() {
        guard let result = selectedResult else { return }
        
        selectedLatitude = result.coordinate.latitude
        selectedLongitude = result.coordinate.longitude
        selectedName = result.name
        
        if radius == nil {
            radius = 100
        }
        
        HapticManager.shared.success()
        dismiss()
    }
}
