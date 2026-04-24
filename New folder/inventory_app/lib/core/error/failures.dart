abstract class Failure {
  final String message;
  Failure(this.message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure(super.message);
}

class ValidationFailure extends Failure {
  ValidationFailure(super.message);
}

class StockFailure extends Failure {
  StockFailure(super.message);
}
