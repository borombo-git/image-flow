/// Thrown when ML Kit finds no faces in the provided image.
class NoFacesDetectedException implements Exception {
  const NoFacesDetectedException();
}

/// Thrown when neither faces nor document text are detected in the image.
class NoContentDetectedException implements Exception {
  const NoContentDetectedException();
}
