# Edit Profile API Integration Implementation

This document outlines how the Edit Profile feature is implemented following the API Integration Guide.

## Architecture Overview

### 1. **API Constants** ✓
- **Location**: `core/constants/api_constants.dart`
- **Base URL**: `https://www.pulsify.page/api/v1`
- All API calls go through this centralized base URL

### 2. **API Endpoints** ✓
- **Location**: `core/constants/api_endpoints.dart`
- **Endpoints Used**:
  - `profile(userId)` → `/users/{userId}` (GET - fetch profile)
  - `editProfile(userId)` → `/users/{userId}/edit` (PATCH/PUT - update profile)

### 3. **API Service** ✓
- **Location**: `core/services/api_service.dart`
- **Methods Used**:
  - `patch()` - For updating only text fields (username, bio, email)
  - `putMultipart()` - For updating with image uploads
- **Features**:
  - Automatic bearer token authorization
  - Request timeout handling (60 seconds)
  - Error parsing and reporting
  - No raw HTTP calls - all requests go through this service

### 4. **Feature Service** ✓
- **Location**: `core/services/profile_service.dart`
- **Methods**:
  - `getProfile(userId)` - Fetches profile data
  - `updateProfile()` - Updates profile with smart logic:
    - If image present: Uses `putMultipart()` for form-data upload
    - If text only: Uses `patch()` for JSON payload
    - Sends: username, bio, email, and avatar (binary or path)
- **Error Handling**: Rethrows exceptions for provider to handle

### 5. **Data Models** ✓
- **Location**: `features/profile/models/profile_data.dart`
- **Fields**: username, bio, email, avatarPath, avatarBytes
- **Smart Field Mapping**: `fromJson()` accepts multiple field name variations:
  - `avatarPath`, `avatar_url`, `avatarUrl`, `profileImageUrl`
  - `username`, `name`
  - `bio`, `description`, `about`
  - `email`
- **toJson()**: Properly serializes fields for API requests

### 6. **State Management** ✓
- **Location**: `providers/profile_provider.dart`
- **Responsibilities**:
  - Manages loading state (`_isLoading`)
  - Manages error state (`_errorMessage`)
  - Caches profile data (`_profile`)
- **Methods**:
  - `loadProfile()` - Fetches and notifies UI
  - `updateProfile()` - Updates and notifies UI with proper state management
  - `clearError()` - Manual error clearing

### 7. **UI Screen** ✓
- **Location**: `features/profile/screens/edit_profile_screen.dart`
- **Features**:
  - ✓ No raw HTTP calls - uses provider only
  - ✓ Loading indicator (spinner button)
  - ✓ Button disabled during loading
  - ✓ Waits for API response before showing success
  - ✓ Error handling with error message display
  - ✓ Proper mounted checks after async operations
  - ✓ Dismisses screen on successful save
- **User Interactions**:
  - Image picker integrates with profile updates
  - All fields (username, bio, email) are editable
  - Changes are sent to backend on "Save Changes"

## Request/Response Flow

### 1. User Makes Changes
```dart
// EditProfileScreen shows form with current profile data
_usernameController.text = profile.username
_bioController.text = profile.bio
_emailController.text = profile.email
_avatarBytes = picked image or existing avatar
```

### 2. User Clicks "Save Changes"
```dart
// Provider receives update request
updateProfile(
  userId: authProvider.currentUser.id,
  newProfile: ProfileData(
    username: _usernameController.text,
    bio: _bioController.text,
    email: _emailController.text,
    avatarBytes: _avatarBytes
  )
)
```

### 3. Service Determines Upload Method
```dart
if (avatarBytes != null) {
  // Send as multipart form-data
  putMultipart(fields: {username, bio, email}, files: {avatar})
} else {
  // Send as JSON
  patch(body: {username, bio, email, avatarPath})
}
```

### 4. API Response
```dart
// Backend returns updated ProfileData
{
  "username": "new_username",
  "bio": "new bio",
  "email": "new_email",
  "avatarUrl": "https://..."
}
```

### 5. UI Updates
```dart
// Profile provider notifies listeners
notifyListeners()

// Screen shows success message
ScaffoldMessenger.showSnackBar("Changes saved successfully!")

// Screen navigates back
Navigator.pop(context)
```

## Best Practices Implemented

✅ **1. Centralized Constants**: All endpoints and base URLs in constants files  
✅ **2. Shared Request Methods**: Uses `api_service.dart` for all HTTP calls  
✅ **3. No Raw HTTP Calls**: No direct http.Client usage in screens  
✅ **4. Feature-based Organization**: Service and models in feature folder  
✅ **5. Request/Response Matching**: Models handle multiple field name variations  
✅ **6. Provider State Management**: Proper loading/error/success states  
✅ **7. User Feedback**: Loading spinners, success messages, error messages  
✅ **8. Bearer Token**: Automatic authorization on all requests  
✅ **9. Error Handling**: Proper exception handling and user feedback  
✅ **10. Mounted Checks**: Safe async operations in UI  

## Testing Checklist

- [ ] Test profile load on app start
- [ ] Test editing username only
- [ ] Test editing bio only  
- [ ] Test editing email only
- [ ] Test changing profile picture only
- [ ] Test editing all fields + picture together
- [ ] Test with slow network (loading indicator visible)
- [ ] Test with network error (error message shown)
- [ ] Test with invalid data (API validation feedback)
- [ ] Test successful save navigates back
- [ ] Verify changes persist after app restart

## API Endpoint Details

### GET /users/:userId
- **Purpose**: Fetch user profile
- **Auth**: Required (Bearer token)
- **Response**: ProfileData object

### PATCH /users/:userId/edit
- **Purpose**: Update profile without image
- **Auth**: Required (Bearer token)
- **Body**: `{username?, bio?, email?, avatarPath?}` (JSON)
- **Response**: Updated ProfileData object

### PUT /users/:userId/edit (Multipart)
- **Purpose**: Update profile with image
- **Auth**: Required (Bearer token)
- **Body**: Form-data with fields + files
  - Fields: username, bio, email
  - Files: avatar (binary)
- **Response**: Updated ProfileData object
