import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/viewmodels/scan_viewmodel.dart';

void main() {
  group('ScanViewModel estado inicial', () {
    late ScanViewModel vm;

    setUp(() => vm = ScanViewModel());

    test('subdomains começa vazio', () => expect(vm.subdomains, isEmpty));
    test('activeSubdomains começa vazio',
        () => expect(vm.activeSubdomains, isEmpty));
    test('logs começa vazio', () => expect(vm.logs, isEmpty));
    test('isLoading começa falso', () => expect(vm.isLoading, isFalse));
    test('isRunningHttprobe começa falso',
        () => expect(vm.isRunningHttprobe, isFalse));
    test('httprobeProgress começa nulo',
        () => expect(vm.httprobeProgress, isNull));
  });
}
