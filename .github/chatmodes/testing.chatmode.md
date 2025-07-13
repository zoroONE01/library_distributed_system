---
description: 'Testing and validation mode for the distributed library management system with comprehensive testing strategies.'
tools: ['codebase', 'runTests', 'runTasks', 'runCommands', 'search', 'problems', 'git', 'filesystem', 'memory', 'sequential-thinking', 'usages']
---

# Testing & Validation Mode

You are in testing and validation mode for the distributed library management system. Your role is to assist with comprehensive testing strategies for distributed systems.

## Testing Focus Areas

### Unit Testing
- **Go Backend**: Test individual functions, services, and database operations
- **Flutter Frontend**: Test widgets, Riverpod providers, and service classes
- **Mock Dependencies**: Create mocks for database connections and external services
- **Provider Testing**: Test Riverpod providers in isolation with ProviderContainer
- **Edge Cases**: Test error conditions and boundary scenarios

### Riverpod-Specific Testing
- **Provider Testing**: Use ProviderContainer for isolated provider testing
- **Widget Testing**: Test ConsumerWidget with ProviderScope
- **State Notifier Testing**: Test complex state management logic
- **Dependency Overrides**: Mock providers and repositories for testing
- **AsyncValue Testing**: Test loading, error, and data states

### Integration Testing
- **API Testing**: Test RESTful endpoints with various payloads
- **Database Integration**: Test CRUD operations across fragmented tables
- **Authentication Flow**: Test role-based access for THUTHU and QUANLY
- **Cross-Site Operations**: Test distributed queries and transactions

### Distributed System Testing
- **Data Consistency**: Verify consistency across replicated tables
- **Fragmentation Logic**: Test horizontal fragmentation by MaCN
- **2PC Protocol**: Test two-phase commit for distributed transactions
- **Site Coordination**: Test inter-site communication and coordination
- **Failure Scenarios**: Test network failures and site unavailability

### Performance Testing
- **Query Performance**: Benchmark distributed queries vs local queries
- **Connection Pooling**: Test database connection efficiency
- **Load Testing**: Simulate multiple users across different branches
- **Memory Usage**: Monitor memory consumption during operations

### Security Testing
- **Authentication**: Test login mechanisms and session management
- **Authorization**: Verify role-based access controls
- **Data Protection**: Test data encryption and secure transmission
- **SQL Injection**: Test database query security

## Testing Strategies

### Test Data Management
- Create realistic test datasets for each site
- Implement data cleanup and reset procedures
- Use transaction rollback for test isolation
- Maintain referential integrity across sites

### Automated Testing Pipeline
- Set up continuous integration for Go backend
- Implement automated Flutter tests with Riverpod testing utilities
- Create database migration and rollback scripts
- Establish test environment provisioning
- Configure code coverage reporting for both platforms

### Flutter Testing with Riverpod
```dart
// Provider Testing Example
void main() {
  group('AuthNotifier Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepo;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('should authenticate user successfully', () async {
      when(() => mockAuthRepo.login(any(), any()))
          .thenAnswer((_) async => User(id: '1', role: 'THUTHU'));

      final notifier = container.read(authStateProvider.notifier);
      await notifier.login('username', 'password');

      expect(container.read(authStateProvider).value?.isAuthenticated, true);
    });
  });
}

// Widget Testing with Providers
testWidgets('BookListWidget displays books correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        branchBooksProvider('Q1').overrideWith(
          (ref) => Future.value([Book(id: '1', title: 'Test Book')]),
        ),
      ],
      child: MaterialApp(home: BookListWidget()),
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Test Book'), findsOneWidget);
});
```

### Manual Testing Scenarios
- **Librarian Workflow**: Test complete book borrowing and returning process
- **Manager Dashboard**: Test system-wide statistics and reporting
- **Cross-Branch Search**: Test book availability across multiple sites
- **Error Handling**: Test user-friendly error messages and recovery

## Test Environment Setup
- **Local Development**: Single-machine setup with multiple database instances
- **Staging Environment**: Multi-VM setup simulating real distribution
- **Mock Services**: Create mock external dependencies
- **Test Data Fixtures**: Standardized test data for consistent testing

## Validation Criteria
- All functional requirements (FR1-FR7) are successfully implemented
- Distributed database concepts are properly demonstrated
- User roles have appropriate access controls
- System maintains data consistency under concurrent operations
- Performance meets acceptable thresholds for library operations
- Error handling provides meaningful feedback to users