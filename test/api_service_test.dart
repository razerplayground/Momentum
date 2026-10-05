import 'dart:convert';
import 'dart:io';
import 'package:bussiness_management/core/constants/app_constants.dart';
import 'package:bussiness_management/data/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('momentum_api_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('creates an employee from a nested API response', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'employee': {
                'id': 'employee-1',
                'name': 'Jane Doe',
                'email': 'jane@example.com',
              },
            },
          }),
          201,
        );
      }),
    );

    final employee = await service.createEmployee('business-1', {
      'name': 'Jane Doe',
      'email': 'jane@example.com',
      'title': 'Designer',
      'department': 'Product',
    });

    expect(employee['id'], 'employee-1');
    expect(capturedRequest?.method, 'POST');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/employees',
    );
    expect(
      jsonDecode(capturedRequest!.body),
      {
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'title': 'Designer',
        'department': 'Product',
      },
    );
  });

  test('loads the created employee if create returns an empty response',
      () async {
    var requestCount = 0;
    final service = ApiService(
      client: MockClient((request) async {
        requestCount++;
        if (request.method == 'POST') {
          return http.Response('', 201);
        }
        return http.Response(
          jsonEncode([
            {
              'id': 'employee-2',
              'name': 'Alex Smith',
              'email': 'alex@example.com',
            }
          ]),
          200,
        );
      }),
    );

    final employee = await service.createEmployee('business-1', {
      'name': 'Alex Smith',
      'email': 'alex@example.com',
      'title': 'Analyst',
      'department': 'Operations',
    });

    expect(employee['id'], 'employee-2');
    expect(requestCount, 2);
  });

  test('preserves the server message when employee creation is forbidden',
      () async {
    final service = ApiService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'statusCode': 403,
              'message':
                  'This business is on the Individual plan — upgrade to Organization to add employees',
              'error': 'Forbidden',
            }),
            403,
            headers: {'content-type': 'application/json; charset=utf-8'},
          )),
    );

    await expectLater(
      service.createEmployee('business-1', {
        'name': 'Alex Smith',
        'email': 'alex@example.com',
        'title': 'Analyst',
        'department': 'Operations',
      }),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.message,
              'message',
              'This business is on the Individual plan — upgrade to Organization to add employees',
            ),
      ),
    );
  });

  test('updates an employee with PATCH and the saved bearer token', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    await service.updateEmployee('business-1', 'employee-1', {
      'title': 'Designer',
      'status': 'active',
    });

    expect(capturedRequest?.method, 'PATCH');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/employees/employee-1',
    );
    expect(
      capturedRequest?.headers['authorization'],
      'Bearer test-access-token',
    );
    expect(
      jsonDecode(capturedRequest!.body),
      {'title': 'Designer', 'status': 'active'},
    );
  });

  test('deletes an employee with DELETE and the saved bearer token', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    await service.deleteEmployee('business-1', 'employee-1');

    expect(capturedRequest?.method, 'DELETE');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/employees/employee-1',
    );
    expect(
      capturedRequest?.headers['authorization'],
      'Bearer test-access-token',
    );
  });

  test('gets jobs for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'jobs': [
                {'id': 'job-1', 'title': 'Site work', 'status': 'pending'}
              ]
            }
          }),
          200,
        );
      }),
    );

    final jobs = await service.getJobs('business-1');

    expect(jobs.single['id'], 'job-1');
    expect(capturedRequest?.method, 'GET');
    expect(capturedRequest?.url.path, '/v1/businesses/business-1/jobs');
  });

  test('creates a job with title description and status', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'job': {
              'id': 'job-1',
              'title': 'Site work',
              'description': 'Prepare the site',
              'status': 'pending',
            }
          }),
          201,
        );
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final job = await service.createJob('business-1', {
      'title': 'Site work',
      'description': 'Prepare the site',
      'status': 'pending',
    });

    expect(job['id'], 'job-1');
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/v1/businesses/business-1/jobs');
    expect(capturedRequest?.headers['authorization'], isNotNull);
    expect(
      jsonDecode(capturedRequest!.body),
      {
        'title': 'Site work',
        'description': 'Prepare the site',
        'status': 'pending',
      },
    );
  });

  test('updates a job with PATCH', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );

    await service.updateJob('business-1', 'job-1', {'status': 'completed'});

    expect(capturedRequest?.method, 'PATCH');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/jobs/job-1',
    );
    expect(jsonDecode(capturedRequest!.body), {'status': 'completed'});
  });

  test('deletes a job with DELETE', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );

    await service.deleteJob('business-1', 'job-1');

    expect(capturedRequest?.method, 'DELETE');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/jobs/job-1',
    );
  });

  test('gets payroll entries for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'entries': [
                {'id': 'payroll-1', 'amount': 4200}
              ]
            }
          }),
          200,
        );
      }),
    );

    final entries = await service.getPayroll('business-1');

    expect(entries.single['id'], 'payroll-1');
    expect(capturedRequest?.method, 'GET');
    expect(capturedRequest?.url.path, '/v1/businesses/business-1/payroll');
  });

  test('gets payroll summary for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'summary': {'totalPayroll': 4200, 'employeeCount': 2}
          }),
          200,
        );
      }),
    );

    final summary = await service.getPayrollSummary('business-1');

    expect(summary['totalPayroll'], 4200);
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/payroll/summary',
    );
  });

  test('runs payroll with the caller-provided payload', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'message': 'Payroll started'}), 201);
      }),
    );
    await service.saveTokens(access: 'test-access-token');
    const payload = {
      'period': '2026-10',
      'employeeIds': ['employee-1']
    };

    final response = await service.runPayroll('business-1', payload);

    expect(response['message'], 'Payroll started');
    expect(capturedRequest?.method, 'POST');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/payroll/run',
    );
    expect(
      capturedRequest?.headers['authorization'],
      'Bearer test-access-token',
    );
    expect(jsonDecode(capturedRequest!.body), payload);
  });

  test('updates a payroll entry with PATCH', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );
    const payload = {'status': 'paid'};

    await service.updatePayrollEntry('business-1', 'entry-1', payload);

    expect(capturedRequest?.method, 'PATCH');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/payroll/entry-1',
    );
    expect(jsonDecode(capturedRequest!.body), payload);
  });

  test('deletes a payroll entry with DELETE', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );

    await service.deletePayrollEntry('business-1', 'entry-1');

    expect(capturedRequest?.method, 'DELETE');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/payroll/entry-1',
    );
  });
}
