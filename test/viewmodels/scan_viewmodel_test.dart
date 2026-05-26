import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/viewmodels/scan_viewmodel.dart';

void main() {
  group('ScanViewModel initial state', () {
    late ScanViewModel vm;

    setUp(() => vm = ScanViewModel());

    test('subdomains is empty', () => expect(vm.subdomains, isEmpty));
    test('activeSubdomains is empty', () => expect(vm.activeSubdomains, isEmpty));
    test('logs is empty', () => expect(vm.logs, isEmpty));
    test('isLoading is false', () => expect(vm.isLoading, isFalse));
    test('isRunningHttprobe is false', () => expect(vm.isRunningHttprobe, isFalse));
    test('httprobeProgress is null', () => expect(vm.httprobeProgress, isNull));
  });
}
