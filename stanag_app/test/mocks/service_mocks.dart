import 'package:mocktail/mocktail.dart';
import 'package:stanag_app/services/auth_service.dart';
import 'package:stanag_app/services/purchase_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockPurchaseService extends Mock implements PurchaseService {}
