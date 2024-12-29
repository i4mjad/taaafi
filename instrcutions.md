Sure, I’ve updated your `.md` file based on your comments. Below is the revised version incorporating all your specifications:

---

### Implementation Guidelines

### Overview

This document guides AI tools to implement any feature in this app. I'm using Firebase as my backend.

1. **Project Architecture**:
   Each feature in the app should follow a three-layer architecture:

   1. **Notifier Layer** (State Management):

      - Use Riverpod with `@riverpod` annotation.
      - Inject and use services using `ref.read`.
      - Handle state updates and UI logic.
      - The state type should always be `AsyncValue<YourType>` with a `build` method of type `FutureOr<YourType>`.
      - **Add comments** within the code to explain the purpose of each method and state transition.
      - Example structure:

      ```
        @riverpod
        class MyNotifier extends _$MyNotifier {
            late final MyService _service;

            @override
            FutureOr<AsyncValue<List<MyModel>>> build() async {
                // Inject the service using ref.read
                _service = ref.read(myServiceProvider);
                // Fetch initial data
                return AsyncValue.data(await _service.getData());
            }

            /// Performs an action and updates the state accordingly
            Future<void> performAction() async {
                // Set state to loading
                state = const AsyncValue.loading();
                try {
                    // Perform the action using the service
                    await _service.doSomething();
                    // Update state with new data
                    state = AsyncValue.data(await build());
                } catch (e, st) {
                    // Set state to error with proper error handling
                    state = AsyncValue.error(e, st);
                }
            }
        }
      ```

   2. **Service Layer** (Business Logic):

      - Handle business logic and computations.
      - Inject and use repositories.
      - Use `async/await` for asynchronous operations.
      - Wrap operations in try-catch blocks and use error snackbars when there is an error.
      - Example structure:

      ```
        class MyService {
            final MyRepository _repository;

            MyService(this._repository);

            /// Fetches data from the repository
            Future<List<MyModel>> getData() async {
                try {
                    return await _repository.fetchData();
                } catch (e) {
                    // Use predefined snackbars to show error messages
                    showErrorSnackbar(e);
                    rethrow;
                }
            }

            /// Performs business logic actions
            Future<void> doSomething() async {
                try {
                    // Business logic here
                } catch (e) {
                    showErrorSnackbar(e);
                    rethrow;
                }
            }

            // Additional business logic methods...
        }
      ```

   3. **Repository Layer** (Data Access):

      - Handle all Firestore/database operations.
      - Implement CRUD operations.
      - **Enforce documentation** for each method.
      - **Write optimized Firestore queries**.
      - Example structure:

      ```
            class MyRepository {
                final FirebaseFirestore _firestore;

                MyRepository(this._firestore);

                /// Creates a new data entry in Firestore
                Future<void> createData(MyModel data) async {
                    // Optimized Firestore operations...
                }

                /// Fetches data from Firestore with optimized queries
                Future<List<MyModel>> fetchData() async {
                    // Example of an optimized query
                    final querySnapshot = await _firestore
                        .collection('my_collection')
                        .where('field', isEqualTo: 'value')
                        .orderBy('createdAt')
                        .get();
                    return querySnapshot.docs.map((doc) => MyModel.fromFirestore(doc)).toList();
                }

                // Additional CRUD methods with documentation...
            }
      ```

2. **Error Handling**:

   - Always wrap Firestore operations in try-catch blocks.
   - Use predefined snackbars from `lib/core/shared_widgets/snackbar.dart`.
   - Propagate errors up through the layers appropriately.
   - **Future Implementation**: Structure code to facilitate easy addition of error logging in the future.
   - Errors should be shown through a snackbar with a proper, translated message.
   - Example usage:

   ```dart
   try {
       // Firestore operation
   } catch (e, st) {
       // Show error snackbar with a translated message
       showErrorSnackbar(AppLocalization.of(context).translate('error_message_key'));
       // Optionally rethrow or handle the error
   }
   ```

3. **UI Guidelines**:

   - Use theme colors: `final theme = AppTheme.of(context)`.
   - Access colors via: `theme.primary[600]`.
   - All text must use localization:
     ```dart
     AppLocalization.of(context).translate('your_key')
     ```
   - Use shared widgets from `lib/core/shared_widgets`.
   - Ensure all UI components are **responsive across all mobile devices** to avoid overflow problems.
   - **Handle long text properly** to prevent overflow issues.
   - To display a message to the user, use the predefined snackbars.

4. **Firestore Best Practices**:

   - Create appropriate indexes for queries, **suggesting an index when required**.
   - Use batch operations for multiple writes.
   - Implement proper security rules:
     - Ensure that documents under a user ID are **accessible only by that user**.
     - **Feel free to suggest any additional security rules** that will help secure the data.
   - Structure collections and documents efficiently.
   - For data modeling:
     - **Model according to Firestore best practices**, considering relationships, frequency of changes, and other influencing factors.
     - Example guidance:
       - Use subcollections for related data that is frequently accessed together.
       - Denormalize data where it improves read performance.
       - Avoid deeply nested structures that can complicate queries.

5. **Edge Cases**:

   - Based on the provided requirements, AI should **predict and handle all possible edge cases** to ensure there are no broken flows in the process.
   - Examples of edge cases should be considered relevant to the specific feature being implemented.

6. **State Management**:

   - Always use Riverpod with `@riverpod` annotation.
   - **Keep providers scoped appropriately to each feature** (feature-specific).
   - Handle loading and error states properly.

7. **Performance Considerations**:

   - Optimize Firestore queries to reduce latency and cost.
   - Implement efficient data pagination where needed.
   - Cache data when appropriate to improve performance.
   - Use streams for real-time updates when necessary.
   - **Introduce lazy loading when suitable** to enhance performance.

8. **Localization**:

   - Add all strings to:
     - `assets/i18n/ar.json` (Arabic)
     - `assets/i18n/en.json` (English)
   - Never hardcode strings in the UI.
   - **Follow the existing localization implementation strictly**.

9. **Testing**:

   - _Testing guidelines are not required at this time._

---

### Additional Recommendations

2. **Documentation Standards:**

   - Encourage writing comprehensive documentation for each feature, including API contracts, data models, and usage instructions.

3. **Code Quality:**

   - Recommend using linters and formatters to maintain code quality and consistency across the project.

4. **Dependency Management:**

   - Provide instructions on managing dependencies, including version constraints and updates.

5. **Deployment Guidelines:**

   - Outline steps for deploying new features, including any necessary configurations or migrations.

6. **Security Best Practices:**
   - Beyond Firestore security rules, address other security aspects such as authentication, authorization, and data encryption.
