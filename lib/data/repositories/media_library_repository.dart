import '../../domain/models/library_track.dart';
import '../services/database_service.dart';

abstract class MediaLibraryRepository {
  Future<List<LibraryTrack>> getAllTracks();
  Future<LibraryTrack?> getTrackById(String id);
  Future<void> insertTrack(LibraryTrack track);
  Future<void> insertTracksBatch(List<LibraryTrack> tracks);
  Future<void> updateTrack(LibraryTrack track);
  Future<void> deleteTrack(String id);
  Future<List<LibraryTrack>> searchTracks(String query, {AudioBusType? filterBus});
}

class SqliteMediaLibraryRepository implements MediaLibraryRepository {
  final DatabaseService _db;

  SqliteMediaLibraryRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  @override
  Future<List<LibraryTrack>> getAllTracks() => _db.getAllTracks();

  @override
  Future<LibraryTrack?> getTrackById(String id) => _db.getTrackById(id);

  @override
  Future<void> insertTrack(LibraryTrack track) => _db.insertTrack(track);

  @override
  Future<void> insertTracksBatch(List<LibraryTrack> tracks) => _db.insertTracksBatch(tracks);

  @override
  Future<void> updateTrack(LibraryTrack track) => _db.updateTrack(track);

  @override
  Future<void> deleteTrack(String id) => _db.deleteTrack(id);

  @override
  Future<List<LibraryTrack>> searchTracks(String query, {AudioBusType? filterBus}) =>
      _db.searchTracks(query, filterBus: filterBus);
}
