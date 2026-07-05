import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/ui/features/auth/view_models/login_view_model.dart';

void main() {
  group('LoginViewModel Tests', () {
    late LoginViewModel viewModel;

    setUp(() {
      viewModel = LoginViewModel();
    });

    test('initial state is correct', () {
      expect(viewModel.state, LoginState.idle);
      expect(viewModel.isSignUp, false);
      expect(viewModel.errorMessage, '');
      expect(viewModel.isAdmin, false);
      expect(viewModel.email, '');
      expect(viewModel.password, '');
    });

    test('toggleMode switches isSignUp and clears errors', () {
      viewModel.toggleMode();
      expect(viewModel.isSignUp, true);
      
      viewModel.toggleMode();
      expect(viewModel.isSignUp, false);
    });

    test('setEmail sets clean trimmed email values', () {
      viewModel.setEmail('  citizen@civicvoice.net   ');
      expect(viewModel.email, 'citizen@civicvoice.net');
    });

    test('setPassword sets passwords correctly', () {
      viewModel.setPassword('securepassword');
      expect(viewModel.password, 'securepassword');
    });

    test('canSubmit is validated correctly', () {
      expect(viewModel.canSubmit, false);
      
      viewModel.setEmail('citizen@civicvoice.net');
      expect(viewModel.canSubmit, false);

      viewModel.setPassword('securepassword');
      expect(viewModel.canSubmit, true);
    });

    test('reset clears error and admin status', () {
      viewModel.setEmail('admin@civicvoice.gov');
      viewModel.setPassword('adminpass');
      
      viewModel.reset();
      expect(viewModel.state, LoginState.idle);
      expect(viewModel.isAdmin, false);
      expect(viewModel.errorMessage, '');
    });
  });
}
