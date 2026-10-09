import 'dart:convert';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AwsAmplifyConfig {
  const AwsAmplifyConfig._();

  static const String region = String.fromEnvironment(
    'AWS_REGION',
    defaultValue: 'us-east-1',
  );

  static const String userPoolId = String.fromEnvironment(
    'COGNITO_USER_POOL_ID',
  );

  static const String userPoolClientId = String.fromEnvironment(
    'COGNITO_USER_POOL_CLIENT_ID',
  );

  static const String identityPoolId = String.fromEnvironment(
    'COGNITO_IDENTITY_POOL_ID',
  );

  static Future<void> configure() async {
    if (userPoolId.isEmpty ||
        userPoolClientId.isEmpty ||
        identityPoolId.isEmpty) {
      throw StateError(
        'Falta configuración AWS Cognito. Ejecute Flutter mediante scripts/aws/Run-AppKmAwsStaging.ps1.',
      );
    }

    await Amplify.addPlugin(AmplifyAuthCognito());

    final config = jsonEncode({
      'version': '1',
      'auth': {
        'aws_region': region,
        'user_pool_id': userPoolId,
        'user_pool_client_id': userPoolClientId,
        'identity_pool_id': identityPoolId,
        'username_attributes': ['email'],
        'standard_required_attributes': ['email'],
        'user_verification_types': ['email'],
        'unauthenticated_identities_enabled': false,
        'password_policy': {
          'min_length': 8,
          'require_lowercase': true,
          'require_uppercase': true,
          'require_numbers': true,
          'require_symbols': false,
        },
      },
    });

    await Amplify.configure(config);
  }
}
