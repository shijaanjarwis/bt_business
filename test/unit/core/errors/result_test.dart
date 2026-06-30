import 'package:bt_business/core/errors/exception_mapper.dart';
import 'package:bt_business/core/errors/exceptions.dart';
import 'package:bt_business/core/errors/failures.dart';
import 'package:bt_business/core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Success exposes value', () {
      const result = Success(42);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('Error exposes failure', () {
      const result = Error<int>(ValidationFailure('invalid'));
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('map transforms success value', () {
      const result = Success(2);
      final mapped = result.map((value) => value * 3);
      expect(mapped, isA<Success<int>>());
      expect((mapped as Success).value, 6);
    });

    test('map preserves error', () {
      const result = Error<int>(ValidationFailure('invalid'));
      final mapped = result.map((value) => value * 3);
      expect(mapped, isA<Error<int>>());
    });
  });

  group('ExceptionMapper', () {
    test('maps validation exception', () {
      final failure = ExceptionMapper.map(const ValidationException('bad input'));
      expect(failure, isA<ValidationFailure>());
    });

    test('maps database exception', () {
      final failure = ExceptionMapper.map(const DatabaseException('db down'));
      expect(failure, isA<DatabaseFailure>());
    });

    test('passes through existing failure', () {
      const failure = UnexpectedFailure('already mapped');
      expect(ExceptionMapper.map(failure), same(failure));
    });

    test('maps unknown errors', () {
      final failure = ExceptionMapper.map(Exception('boom'));
      expect(failure, isA<UnexpectedFailure>());
    });
  });
}
