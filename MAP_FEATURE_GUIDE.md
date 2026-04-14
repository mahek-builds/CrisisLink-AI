# Map Feature Implementation Guide

## Overview
The Map Incidents feature has been successfully added to the CrisisLink-AI Flutter app. This feature allows users to visualize active incidents on an interactive Google Map with real-time data from the backend.

## Features Implemented

### 1. **Interactive Map Display**
   - Displays all active incidents from the backend API
   - Auto-centers and zooms to fit all markers
   - Color-coded markers based on incident priority:
     - 🔴 **CRITICAL** - Red
     - 🟠 **HIGH** - Orange
     - 🟡 **MEDIUM** - Yellow
     - 🟢 **LOW** - Green

### 2. **Incident Information Display**
   - Tap on any marker to view incident details in a bottom sheet
   - Shows:
     - Incident type
     - Priority level with color badge
     - Exact coordinates (latitude & longitude)
     - Number of reporters
     - Current status (Active/In-Progress/Resolved)
   - Quick action buttons: "View Details" and "Assign"

### 3. **Incident List View**
   - Horizontal scrollable list at the bottom of the map
   - Shows all active incidents with summary information
   - Tap any incident card to focus on that marker and show details
   - Visual indicators for priority and reporter count

### 4. **Real-time Updates**
   - Refresh button to reload incidents from the backend
   - Automatic marker regeneration
   - Loading state with progress indicator
   - Error handling with user-friendly messages

### 5. **Navigation Integration**
   - Accessible from:
     - Main SOS Home Page (map icon in top-right)
     - Admin Dashboard (map icon in header)
     - Responder Dashboard (map icon in header)

## Technical Details

### New Files Created
- **`lib/screens/map_incidents_page.dart`** - Main map screen component

### Dependencies Added
- **`google_maps_flutter: ^2.6.0`** - Google Maps integration

### Updated Files
- **`pubspec.yaml`** - Added google_maps_flutter dependency
- **`lib/screens/sos_home_page.dart`** - Added map navigation button
- **`lib/screens/admin_dashboard_page.dart`** - Added map navigation button
- **`lib/screens/responder_dashboard_page.dart`** - Added map navigation button

## Architecture

### MapIncidentsPage Class Structure
```
MapIncidentsPage (StatefulWidget)
├── _mapController (GoogleMapController)
├── _incidents (List<IncidentSummary>)
├── _markers (Set<Marker>)
├── _selectedIncident (IncidentSummary?)
├── _loadIncidents() - Fetch from API
├── _generateMarkers() - Create map markers
├── _showIncidentDetails() - Display bottom sheet
└── _fitAllMarkers() - Auto-center on markers
```

### Color Mapping
```dart
static const Map<String, Color> _priorityColors = {
  'CRITICAL': Color(0xFFFF0000),  // Red
  'HIGH': Color(0xFFFFA500),      // Orange
  'MEDIUM': Color(0xFFFFFF00),    // Yellow
  'LOW': Color(0xFF00FF00),       // Green
};
```

## API Integration

### Backend Endpoint Used
```
GET /api/incidents/active
```

### Response Model
```dart
List<IncidentSummary> {
  id: String (UUID)
  latitude: double
  longitude: double
  type: String (fire|medical|police|other)
  priority: String (CRITICAL|HIGH|MEDIUM|LOW)
  status: String (active|in-progress|resolved)
  uniqueReporters: int
  createdAt: DateTime
}
```

## User Experience Flow

### 1. **Access the Map**
   ```
   Option A: SOS Home → Map Icon (top-right) → Map View
   Option B: Admin/Responder Dashboard → Map Icon → Map View
   ```

### 2. **View Incidents**
   ```
   Map View
   └── Shows all active incidents as color-coded markers
   └── Shows incident list at bottom
   ```

### 3. **Interact with Incidents**
   ```
   Tap on marker OR incident card in list
   ├── Bottom sheet opens with details
   ├── View full incident information
   ├── Option to view details page
   └── Option to assign responder
   ```

### 4. **Refresh Data**
   ```
   Tap refresh button (⟳ icon)
   └── Reload incidents from backend
   └── Update map markers
   └── Update incident list
   ```

## Error Handling

### Error States
- **Loading Error**: Displays error message with retry button
- **No Incidents**: Shows empty map with incident list (if any)
- **Network Error**: Handled by SosApiException with user-friendly message
- **Generic Error**: Falls back to generic error message with retry option

### Resilience Features
- Mounted/unmounted checks to prevent state updates after navigation
- Try-catch blocks for all async operations
- Graceful degradation if incidents list is empty

## Performance Considerations

### Optimization
- Marker generation is batched
- GoogleMap uses efficient rendering
- List view uses horizontal scroll for incidents
- Auto-fit algorithm uses efficient bounds calculation

### Scalability
- Handles multiple incidents (tested with 2+)
- Efficient marker updates
- Smooth camera animations
- Supports all screen sizes

## Future Enhancements

### Potential Improvements
1. **Clustering**: Group nearby incidents when zoomed out
2. **Real-time Updates**: WebSocket for live incident tracking
3. **Filters**: Filter by incident type or priority
4. **Route Optimization**: Show optimal routes to responders
5. **Incident History**: Historical map view of resolved incidents
6. **Custom Map Styles**: Dark theme, custom icon designs
7. **Geofencing**: Alert when responders enter incident zones
8. **Analytics**: Heatmaps of incident hotspots

## Testing Checklist

- ✅ Map loads successfully
- ✅ Markers display with correct colors
- ✅ Tap marker shows bottom sheet
- ✅ Incident list shows at bottom
- ✅ Tap incident card updates map
- ✅ Refresh button reloads data
- ✅ Error handling works
- ✅ Navigation between pages works
- ✅ Back button returns to previous page
- ✅ Memory is managed (dispose called)

## Installation & Setup

### 1. **Get API Key**
   Add your Google Maps API key to your Android/iOS configuration:
   
   **Android**: `android/app/src/main/AndroidManifest.xml`
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY_HERE"/>
   ```
   
   **iOS**: `ios/Runner/GoogleService-Info.plist`

### 2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

### 3. **Run the App**
   ```bash
   flutter run
   ```

## Code Examples

### Access the Map Programmatically
```dart
// From any screen with sosApiService
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => MapIncidentsPage(
      sosApiService: sosApiService,
    ),
  ),
);
```

### Customize Marker Appearance
```dart
// In _generateMarkers() method
final marker = Marker(
  markerId: markerId,
  position: position,
  icon: BitmapDescriptor.defaultMarkerWithHue(
    _getHueFromColor(color),
  ),
);
```

## Troubleshooting

### Map Not Showing
- Ensure Google Maps API key is correctly configured
- Check internet connectivity
- Verify backend is running and returning data

### Markers Not Appearing
- Check if incidents are being loaded from API
- Verify coordinates are valid (latitude: -90 to 90, longitude: -180 to 180)
- Check priority colors are correct

### Bottom Sheet Not Closing
- Check AlertDialog/SnackBar is not blocking
- Try dismissing other overlays first

## Support & Documentation

For more information:
- [Google Maps Flutter Documentation](https://pub.dev/packages/google_maps_flutter)
- [CrisisLink-AI Backend API](../backend_python/README.md)
- [Flutter Best Practices](https://flutter.dev/docs)
