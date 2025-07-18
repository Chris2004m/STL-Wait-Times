# Mapbox Navigation SDK Setup

## Overview
This project now includes turn-by-turn navigation functionality using Mapbox Navigation SDK v3. To build and run the project, you'll need to set up authentication with Mapbox.

## Required Setup

### 1. Mapbox Account Setup
1. Go to [https://account.mapbox.com/auth/signup](https://account.mapbox.com/auth/signup) and create an account
2. Navigate to your account's [Access tokens page](https://account.mapbox.com/access-tokens/)

### 2. Create Secret Token
1. Click "Create a token" 
2. Select the "Downloads:Read" scope
3. Copy the secret token (starts with `sk.`)

### 3. Configure .netrc File
Create a `.netrc` file in your home directory (`~/.netrc`):

```bash
machine api.mapbox.com
login mapbox
password YOUR_SECRET_TOKEN_HERE
```

**Important**: Replace `YOUR_SECRET_TOKEN_HERE` with your actual secret token.

### 4. Set File Permissions
```bash
chmod 600 ~/.netrc
```

## Project Features

### Navigation Capabilities
- **Turn-by-turn navigation** to any medical facility
- **Route calculation** with multiple alternatives
- **Voice guidance** with customizable settings
- **Route visualization** on the 3D map
- **Real-time progress tracking** with ETA updates
- **Offline support** for reliable navigation

### User Experience
- **Tap to navigate**: Simply tap the "Navigate" button on any facility card
- **Seamless integration**: Navigation launches without leaving the app
- **Progress tracking**: See your progress and ETA in real-time
- **Accessibility support**: Full VoiceOver compatibility

### Technical Implementation
- **Mapbox Navigation SDK v3**: Latest navigation technology
- **SwiftUI integration**: Native iOS interface
- **Background location**: Continues navigation when app is backgrounded
- **Voice instructions**: Turn-by-turn audio guidance
- **Route optimization**: Automatic rerouting for traffic and incidents

## Usage

1. **Grant Location Permission**: The app will request location access when first opened
2. **Select a Facility**: Browse the list of nearby medical facilities
3. **Start Navigation**: Tap the "Navigate" button on any facility card
4. **Follow Directions**: The app will provide turn-by-turn directions with voice guidance
5. **Arrive Safely**: The app will notify you when you've reached your destination

## Troubleshooting

### Build Errors
- **401 Authentication Error**: Ensure your .netrc file is properly configured with a valid secret token
- **Permission Denied**: Make sure .netrc file has correct permissions (`chmod 600 ~/.netrc`)
- **Token Expired**: Generate a new secret token from your Mapbox account

### Navigation Issues
- **No Route Found**: Check that location services are enabled and you have a valid GPS signal
- **Navigation Not Starting**: Ensure you have granted location permissions to the app
- **Voice Instructions Not Working**: Check that your device volume is turned up and silent mode is off

## Development Notes

### Key Files Added
- `NavigationService.swift`: Core navigation logic and route calculation
- `NavigationManager.swift`: Navigation UI presentation and lifecycle management
- `NavigationProgressView.swift`: Progress tracking UI component
- Updated `FacilityCard.swift`: Added navigate button functionality
- Updated `MapboxView.swift`: Added route line rendering
- Updated `DashboardView.swift`: Integrated navigation state management

### Testing
- Use iOS Simulator for basic testing
- Physical device recommended for full GPS and location testing
- Test with various facility locations to ensure route calculation works properly

## Next Steps

1. **Test the Navigation**: Try navigating to a few different facilities
2. **Customize Settings**: Adjust voice guidance, route preferences, and UI styling
3. **Add Real Addresses**: Replace placeholder addresses with actual facility addresses
4. **Implement Offline Maps**: Add offline map downloads for areas without internet

## Support

If you encounter any issues:
1. Check the Mapbox documentation: [https://docs.mapbox.com/ios/navigation/](https://docs.mapbox.com/ios/navigation/)
2. Verify your .netrc configuration
3. Ensure you have a valid Mapbox account with proper permissions
4. Test with a physical device if using location services

The navigation feature is now fully integrated and ready for use!