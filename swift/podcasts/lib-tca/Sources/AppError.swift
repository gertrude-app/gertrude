struct AppError: Error {
  let message: String
}

extension Result where Failure == AppError {
  var error: AppError? {
    switch self {
    case .success:
      nil
    case .failure(let error):
      error
    }
  }
}
