import '../datasources/ratings_remote_datasource.dart';
import '../models/rating_model.dart';
import '../../domain/entities/rating.dart';
import '../../domain/repositories/rating_repository.dart';

class RatingRepositoryImpl implements RatingRepository {
  final RatingsRemoteDataSource _remoteDataSource;

  RatingRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Rating>> getUserRatings(String userId) async {
    final models = await _remoteDataSource.getUserRatings(userId);
    return models.map((model) => _modelToEntity(model)).toList();
  }

  @override
  Future<Rating?> getRating(
    String userId,
    String variant,
    String timeControl,
  ) async {
    final model = await _remoteDataSource.getRating(userId, variant, timeControl);
    return model != null ? _modelToEntity(model) : null;
  }

  @override
  Future<Rating> createRatingEntry({
    required String userId,
    required String variant,
    required String timeControl,
    double initialRating = 1500.0,
  }) async {
    final model = await _remoteDataSource.createRatingEntry(
      userId: userId,
      variant: variant,
      timeControl: timeControl,
      initialRating: initialRating,
    );
    return _modelToEntity(model);
  }

  @override
  Future<Rating> updateRating(Rating rating) async {
    final model = _entityToModel(rating);
    final updatedModel = await _remoteDataSource.updateRating(model);
    return _modelToEntity(updatedModel);
  }

  Rating _modelToEntity(RatingModel model) {
    return Rating(
      variant: model.variant,
      timeControl: model.timeControl,
      rating: model.rating,
      lastPlayedAt: model.lastPlayedAt,
    );
  }

  RatingModel _entityToModel(Rating entity) {
    return RatingModel(
      userId: '', // Will be set by the remote data source
      variant: entity.variant,
      timeControl: entity.timeControl,
      rating: entity.rating,
      lastPlayedAt: entity.lastPlayedAt,
    );
  }
}
