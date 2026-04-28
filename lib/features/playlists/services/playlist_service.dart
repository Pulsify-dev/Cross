import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/playlist_model.dart';

class PlaylistService {
  final String baseUrl = "http://127.0.0.1:5000/api/v1";

  // GET: Get All Playlists
  Future<List<Playlist>> getPlaylists(String token) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/playlists"), 
        headers: {'Authorization': 'Bearer $token'}
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        return data.map((e) => Playlist.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error fetching playlists: $e");
    }
    return []; // Return empty list instead of crashing on 502
  }

  // POST: Create Playlist
  Future<Playlist?> createPlaylist(String token, String title) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/playlists"),
        headers: {
          'Authorization': 'Bearer $token', 
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"title": title}),
      );
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Playlist.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print("Error creating playlist: $e");
    }
    return null; 
  }

  Future<bool> updatePrivacy(String token, String id, bool isPublic) async {
    try {
      final res = await http.patch(
        Uri.parse("$baseUrl/playlists/$id"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"isPublic": isPublic}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  Future<bool> addTrack(String token, String playlistId, String trackId) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/playlists/$playlistId/tracks"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({"trackId": trackId}),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  Future<bool> deletePlaylist(String token, String id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/playlists/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}