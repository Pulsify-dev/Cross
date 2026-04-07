# Edit Profile API Integration - Postman API

## Summary of Changes

Successfully integrated the Edit Profile feature with the Pulsify API based on the official Postman documentation.

## API Endpoints Used

### 1. **Get My Profile** (GET `/users/me`)
- Fetches the current user's complete profile
- **Authentication**: Required (Bearer token)
- **Response fields**:
  - `_id`, `username`, `display_name`, `bio`, `is_verified`
  - `avatar_url`, `cover_url`, `track_count`, `followers_count`, `following_count`
  - `social_links` (instagram, x, facebook, website)
  - `tier`, `favorite_genres`, `location`, `is_private`
  - `created_at`, `email`, `playlist_count`, `upload_duration_used_seconds`, `storage_used_bytes`

### 2. **Update My Profile** (PATCH `/users/me`)
- Updates one or more profile fields
- **Authentication**: Required (Bearer token)
- **Request body** (all optional):
  ```json
  {
    "display_name": "John Doe",
    "bio": "Music lover and producer",
    "location": "Cairo",
    "favorite_genres": ["Electronic", "House"],
    "social_links": {
      "instagram": "johndoe_ig",
      "x": "johndoe_x",
      "facebook": "",
      "website": ""
    },
    "is_private": false
  }
  ```
- **Content-Type**: application/json
- **Max field lengths**:
  - `display_name`: 50 chars
  - `bio`: 500 chars
  - `location`: 100 chars

### 3. **Upload Avatar** (POST `/users/me/avatar`)
- Uploads a new profile picture to S3
- **Authentication**: Required (Bearer token)
- **Form data**: Single field `file`
- **Accepted formats**: JPG, PNG, or WebP
- **Max file size**: 5 MB
- **Response**: `{ "url": "https://bucket.s3.region.amazonaws.com/..." }`

## Code Structure

### Files Modified

1. **`lib/core/constants/api_endpoints.dart`**
   - Updated endpoints to use `/users/me` pattern
   - Added separate endpoints for profile and avatar upload

2. **`lib/features/profile/models/profile_data.dart`**
   - Changed field `username` → `display_name`
   - Added new fields: `location`, `iPrivate`, `favoriteGenres`, `socialLinks`
   - Added helper methods for extracting various data types
   - Updated `fromJson()` and `toJson()` methods

3. **`lib/core/services/profile_service.dart`**
   - `getProfile()` - No userId parameter (uses current user endpoint)
   - `updateProfile()` - Takes individual fields instead of whole ProfileData object
   - `_uploadAvatar()` - Separate method for avatar upload (POST `/users/me/avatar`)
   - Smart logic: uploads avatar first via separate endpoint, then updates profile fields

4. **`lib/providers/profile_provider.dart`**
   - Updated `loadProfile()` - No userId parameter required
   - Updated `updateProfile()` - Accepts individual update fields
   - Added Uint8List import for avatar data

5. **`lib/features/profile/screens/edit_profile_screen.dart`**
   - Changed `_usernameController` → `_displayNameController`
   - Added `_locationController` for location field
   - Updated form field labels and initialization
   - Updated save logic to pass individual fields to provider
   - Removed dependency on AuthProvider for userId

6. **`lib/features/profile/screens/user_profile_screen.dart`**
   - Updated `_loadProfile()` to not pass userId
   - Changed `profile.username` → `profile.displayName`

## Request/Response Flow

### User Makes Changes
```
Edit Form Fields:
- Display Name
- Bio
- Location
- Email
- Avatar (optional)
```

### Save Process
```
1. If avatar selected:
   POST /users/me/avatar (form-data with file)
   ↓ Returns avatar URL
2. PATCH /users/me (JSON with updated fields)
   ↓ Returns updated profile
3. Provider updates local cache
4. UI navigates back on success
```

### Error Handling
- Loading spinner shown during save
- Error messages displayed if API fails
- User can retry or cancel

## Key Features Implemented

✅ Use `/users/me` endpoint (current user)  
✅ Separate avatar upload endpoint  
✅ Update individual fields (all optional)  
✅ Support for new fields (location, social_links, favorite_genres, is_private)  
✅ Upload avatar to S3 (handled by backend)  
✅ Proper field name mapping (`display_name` from API)  
✅ Bearer token authentication  
✅ Loading/error/success states  
✅ No userId required (uses authenticated session)  
✅ Smart multipart handling for images  

## Testing Checklist

- [ ] Load profile on app start
- [ ] Edit display name only
- [ ] Edit bio only
- [ ] Edit location
- [ ] Change avatar
- [ ] Edit multiple fields + avatar
- [ ] Verify non-empty fields sent to API
- [ ] Check error messages on network failure
- [ ] Verify profile changes persist
- [ ] Test with network throttling

## API Documentation Reference

Full API documentation: https://documenter.getpostman.com/view/47709542/2sBXinHWMe

Base URL: https://www.pulsify.page/api/v1
