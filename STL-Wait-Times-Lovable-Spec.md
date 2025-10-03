# STL Wait Times - Modern Healthcare Wait Time Tracker

## Project Overview
Create a modern, responsive web application that helps users find the nearest healthcare facilities in the St. Louis metro area and view real-time wait times. The app should have a sleek, contemporary design with smooth animations and an intuitive user experience.

## Core Features

### 1. Interactive Map Dashboard
- **Primary View**: Large interactive map showing healthcare facility locations
- **Map Markers**: Color-coded pins based on wait times:
  - Green (0-20 min): Available/Short wait
  - Orange (21-45 min): Moderate wait
  - Red (46+ min): Long wait
  - Gray: Closed/Unavailable
- **Map Controls**: Zoom, pan, recenter on user location
- **Marker Interaction**: Click markers to highlight and show details

### 2. Bottom Sheet Interface (Flighty-style)
- **Three States**:
  - Peek: Shows 1-2 facility cards with handle to drag
  - Medium: Shows 3-4 facility cards
  - Expanded: Full list with search/filter options
- **Smooth Animations**: Spring-based transitions between states
- **Handle Bar**: Prominent drag handle at top of sheet

### 3. Facility Cards (Modern Design)
Each facility card should display:
- **Header**: Facility name, type badge (ED/UC), status indicator
- **Wait Time**: Large, prominent display with color coding
- **Distance**: From user's location with driving time estimate
- **Address**: Full address below facility name
- **Action Buttons**: 
  - Navigate (opens directions)
  - Call facility
  - Refresh wait time (if stale data)
- **Visual Indicators**: 
  - Loading states with skeleton shimmer
  - Stale data warnings
  - Open/closed status

### 4. Modern UI Styling Requirements

#### Color Scheme
- **Primary**: Modern blue (#007AFF or similar iOS blue)
- **Success**: Green (#34C759) for short waits
- **Warning**: Orange (#FF9500) for moderate waits  
- **Error**: Red (#FF3B30) for long waits
- **Background**: Clean white/gray with proper contrast
- **Dark Mode**: Full dark theme support

#### Typography
- **Headlines**: SF Pro Display or similar modern sans-serif
- **Body**: SF Pro Text with good readability
- **Wait Times**: Bold, prominent numbers
- **Labels**: Clear hierarchy with proper spacing

#### Components & Interactions
- **Buttons**: Rounded, filled style with hover states
- **Cards**: Subtle shadows, rounded corners (12-16px radius)
- **Loading**: Modern skeleton loaders, not spinners
- **Animations**: Smooth 60fps transitions using spring curves
- **Touch Targets**: Minimum 44px for mobile accessibility

### 5. Data Management

#### Sample Facilities Data
```javascript
const sampleFacilities = [
  {
    id: "mercy-gohealth-stones-corner",
    name: "Mercy GoHealth - Stone's Corner",
    type: "urgentCare",
    address: "6055 N Main Street Rd",
    city: "Webb City",
    state: "MO",
    zipCode: "64870",
    phone: "(417) 717-8846",
    coordinates: [37.143563, -94.511307],
    currentWaitTime: 15,
    status: "open",
    hours: "8:00 AM - 8:00 PM",
    distance: "2.3 mi",
    drivingTime: "6 min"
  },
  {
    id: "total-access-university-city",
    name: "Total Access Urgent Care - University City",
    type: "urgentCare", 
    address: "8213 Delmar Blvd",
    city: "University City",
    state: "MO",
    zipCode: "63124",
    phone: "(314) 219-8985",
    coordinates: [38.6560, -90.3090],
    currentWaitTime: 35,
    status: "open",
    hours: "8:00 AM - 8:00 PM",
    distance: "5.1 mi",
    drivingTime: "12 min"
  },
  {
    id: "bjc-emergency-room",
    name: "Barnes-Jewish Hospital Emergency Department",
    type: "emergencyDepartment",
    address: "1 Barnes Jewish Hospital Plaza",
    city: "St. Louis",
    state: "MO", 
    zipCode: "63110",
    phone: "(314) 747-3000",
    coordinates: [38.6362, -90.2636],
    currentWaitTime: 180,
    status: "open",
    hours: "24/7",
    distance: "8.7 mi",
    drivingTime: "18 min"
  }
];
```

### 6. Key User Interactions

#### Map Interactions
- Tap marker → Highlight facility and fly to location
- Tap facility card → Select on map and show details
- Pinch/zoom → Smooth map scaling
- Long press → Show address popup

#### Navigation Flow  
- Main dashboard with map + bottom sheet
- Facility detail modal/page (optional)
- Settings/preferences (filter by type, sort options)

#### Location Services
- Request user permission on load
- Show distance and driving time to each facility
- Auto-sort by proximity when location available
- Fallback to alphabetical sort without location

### 7. Technical Requirements

#### Responsive Design
- Mobile-first approach
- Works on phones, tablets, desktop
- Touch-friendly interactions
- Proper viewport handling

#### Performance
- Fast initial load
- Smooth 60fps animations
- Lazy loading for non-visible content
- Efficient map rendering

#### Accessibility
- Screen reader compatible
- Keyboard navigation
- High contrast support
- Proper ARIA labels

### 8. API Integration (Mock for Demo)
```javascript
// Mock API calls for demo
const fetchWaitTimes = async () => {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Return mock data with random wait times
  return facilities.map(facility => ({
    ...facility,
    currentWaitTime: Math.floor(Math.random() * 120) + 5,
    lastUpdated: new Date().toISOString()
  }));
};
```

### 9. Safety Features
- **Disclaimer Banner**: "Times are estimates. If you think you're having an emergency, call 911."
- **Emergency Button**: Quick access to 911 dialing
- **Data Freshness**: Show when wait times were last updated

## Design Inspiration
- **Flighty App**: Bottom sheet interaction pattern
- **Apple Maps**: Clean map interface
- **Modern iOS**: Rounded cards, spring animations
- **Uber/Lyft**: Location-based service UI patterns

## Success Criteria
- Smooth, responsive interface that feels native
- Clear wait time information at a glance  
- Easy facility discovery and navigation
- Modern aesthetic that doesn't feel clinical
- Accessible to users with disabilities

## Implementation Notes for Lovable
- Use modern CSS Grid/Flexbox for layouts
- Implement CSS custom properties for theming
- Use Web APIs for geolocation
- Consider Mapbox GL JS or similar for maps
- Implement proper loading states throughout
- Add micro-interactions for delight
- Ensure proper error handling and edge cases

This specification should provide enough detail for Lovable to create a modern, functional healthcare wait time application while maintaining the core utility and user experience of the original iOS app.
