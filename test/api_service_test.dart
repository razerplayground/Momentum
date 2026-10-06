import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:bussiness_management/core/constants/app_constants.dart';
import 'package:bussiness_management/data/models/user_model.dart';
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
                  'This business is on the Individual plan â€” upgrade to Organization to add employees',
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
              'This business is on the Individual plan â€” upgrade to Organization to add employees',
            ),
      ),
    );
  });

  test('preserves saved organization plan when profile omits it', () async {
    final service = ApiService(
      client: MockClient((_) async => http.Response(
            jsonEncode({
              'id': 'user-1',
              'email': 'jane@example.com',
              'name': 'Jane Doe',
            }),
            200,
          )),
    );
    await service.saveUserData(UserModel(
      id: 'user-1',
      email: 'jane@example.com',
      name: 'Jane Doe',
      plan: 'organization',
      organizationName: 'Example Organization',
    ));

    final user = await service.getMe();

    expect(user.plan, 'organization');
    expect(user.organizationName, 'Example Organization');
    expect(service.getSavedUserData()?.plan, 'organization');
  });

  test('creates additional businesses through the businesses endpoint',
      () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': {
              'business': {
                'id': 'business-2',
                'name': 'Second Business',
                'industry': 'Technology',
                'address': 'Office address',
              },
            },
          }),
          201,
        );
      }),
    );

    final business = await service.createWorkspace(
      name: 'Second Business',
      industry: 'Technology',
      description: 'Office address',
    );

    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/v1/businesses');
    expect(jsonDecode(capturedRequest!.body), {
      'name': 'Second Business',
      'industry': 'Technology',
      'address': 'Office address',
    });
    expect(business.id, 'business-2');
    expect(business.name, 'Second Business');
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

  test('creates a job using the API required fields', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'job': {
              'id': 'job-1',
              'title': 'Site work',
              'department': 'Construction',
              'status': 'open',
            }
          }),
          201,
        );
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final job = await service.createJob('business-1', {
      'title': 'Site work',
      'department': 'Construction',
      'status': 'open',
    });

    expect(job['id'], 'job-1');
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/v1/businesses/business-1/jobs');
    expect(capturedRequest?.headers['authorization'], isNotNull);
    expect(
      jsonDecode(capturedRequest!.body),
      {
        'title': 'Site work',
        'department': 'Construction',
        'status': 'open',
      },
    );
  });

  test('loads the created job when create returns no job object', () async {
    final requests = <String>[];
    final service = ApiService(
      client: MockClient((request) async {
        requests.add(request.method);
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'message': 'Job created'}), 201);
        }
        return http.Response(
          jsonEncode({
            'data': {
              'jobs': [
                {
                  'id': 'job-2',
                  'title': 'Site work',
                  'department': 'Construction',
                  'status': 'open',
                }
              ],
            },
          }),
          200,
        );
      }),
    );

    final job = await service.createJob('business-1', {
      'title': 'Site work',
      'department': 'Construction',
      'status': 'open',
    });

    expect(requests, ['POST', 'GET']);
    expect(job['id'], 'job-2');
  });

  test('updates a job with PATCH', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response('', 204);
      }),
    );

    await service.updateJob('business-1', 'job-1', {'status': 'closed'});

    expect(capturedRequest?.method, 'PATCH');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/jobs/job-1',
    );
    expect(jsonDecode(capturedRequest!.body), {'status': 'closed'});
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

  test('gets organization report overview', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({'businessCount': 2, 'totalProjects': 5}),
          200,
        );
      }),
    );

    final report = await service.getOrganizationReportOverview();

    expect(report['businessCount'], 2);
    expect(capturedRequest?.method, 'GET');
    expect(capturedRequest?.url.path, '/v1/reports/overview');
  });

  test('gets a business report overview', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'projectCount': 3}), 200);
      }),
    );

    final report = await service.getBusinessReport('business-1');

    expect(report['projectCount'], 3);
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/reports',
    );
  });

  test('gets financial trend for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode([
            {'month': '2026-01', 'income': 5000, 'expense': 2000}
          ]),
          200,
        );
      }),
    );

    final trend = await service.getFinancialTrend('business-1');

    expect(trend.single['income'], 5000);
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/reports/financial-trend',
    );
  });

  test('gets project analytics for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'projects': 4,
            'tasks': {'completed': 8, 'pending': 2},
          }),
          200,
        );
      }),
    );

    final analytics = await service.getProjectAnalytics('business-1');

    expect(analytics['projects'], 4);
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/reports/project-analytics',
    );
  });

  test('gets audit logs for a business', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode([
            {'id': 'audit-1', 'action': 'employee.created'}
          ]),
          200,
        );
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final logs = await service.getAuditLogs('business-1');

    expect(logs.single['action'], 'employee.created');
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.path,
      '/v1/businesses/business-1/audit-logs',
    );
    expect(capturedRequest?.headers['authorization'], startsWith('Bearer '));
  });

  test('exports business records as CSV', () async {
    final requestedPaths = <String>[];
    final service = ApiService(
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        return http.Response('id,name\nrecord-1,Example\n', 200);
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final finances = await service.exportFinances('business-1');
    final payroll = await service.exportPayroll('business-1');
    final employees = await service.exportEmployees('business-1');

    expect(finances, 'id,name\nrecord-1,Example\n');
    expect(payroll, 'id,name\nrecord-1,Example\n');
    expect(employees, 'id,name\nrecord-1,Example\n');
    expect(requestedPaths, [
      '/v1/businesses/business-1/exports/finances',
      '/v1/businesses/business-1/exports/payroll',
      '/v1/businesses/business-1/exports/employees',
    ]);
  });

  test('uploads a file as authenticated multipart form data', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'file': {'filename': 'stored-receipt.png'}
          }),
          201,
        );
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final response = await service.uploadStorageFile(
      'receipt.png',
      Uint8List.fromList([1, 2, 3]),
    );

    expect(response['file']['filename'], 'stored-receipt.png');
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/v1/storage/upload');
    expect(capturedRequest?.headers['authorization'], 'Bearer test-access-token');
    expect(
      capturedRequest?.headers['content-type'],
      startsWith('multipart/form-data; boundary='),
    );
    expect(capturedRequest?.body, contains('filename="receipt.png"'));
    expect(capturedRequest?.body, contains('name="file"'));
  });

  test('downloads stored file bytes with an authenticated request', () async {
    http.Request? capturedRequest;
    final service = ApiService(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response.bytes([0, 1, 2, 255], 200);
      }),
    );
    await service.saveTokens(access: 'test-access-token');

    final bytes = await service.downloadStorageFile('receipt #1.png');

    expect(bytes, [0, 1, 2, 255]);
    expect(capturedRequest?.method, 'GET');
    expect(
      capturedRequest?.url.toString(),
      endsWith('/v1/storage/files/receipt%20%231.png'),
    );
    expect(capturedRequest?.headers['authorization'], 'Bearer test-access-token');
    expect(capturedRequest?.headers['accept'], '*/*');
  });
}
