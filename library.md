- I will list multipule firestore collections , and I will specify the the strcture of the documents inside those, and how are they realted to each other:

  - contentTypes:
    - contentTypeName (string)
    - contentTypeIconName (string)
    - isActive (boolean)
  - contentOwners:
    - ownerName (string)
    - ownerSource (string)
    - isActive (boolean)
  - contentCategories:
    - categoryName (string)
    - contentCategoryIconName (string)
    - isActive (boolean)
  - content:
    - contentCategoryId (string) //document id from the contentCategories collection
    - contentLanguage (string)
    - contentLink (string)
    - contentName (string)
    - contentOwnerId (string) //document id from from contentOwners document
    - contentTypeId (string) //document id from from contentTypes document
    - createdAt(timestamp)
    - isActive (boolean)
    - isDeleted (boolean)
    - updatedAt (timestamp)
  - contentLists:
    - id (string)
    - contentListIconName (string)
    - isActive (boolean)
    - isFeatured (boolean)
    - listContentIds (array)
    - listDescription (string)
    - listName (string)

- I need you to create a full slice (state notifier/service/repository) considering the following requirements:

- The user should be able to get the latest 6 added contents.
- The user should be able to get the featured lists
- The user should be able to see all lists
- The user should be able to view the details of a list
- The user should be able to get all content types, and based on this information, the user can see all of the content related to this content type.
- The user should be able to search, based on a text, this should look in all realted details to contents and content lists so the returned values in this case a list of content and a list of content lists

- If you create any model, you should Prefex it with Cursor[ModelName] just to keep track of it

- **Project Architecture**:
  Each feature in the app should follow a three-layer architecture:

  1.  **Notifier Layer** (State Management):

      - Use Riverpod with `@riverpod` annotation.
      - Inject and use services using `ref.read`.
      - Handle state updates and UI logic.
      - The state type should always be `AsyncValue<YourType>` with a `build` method of type `FutureOr<YourType>`.
      - **Add comments** within the code to explain the purpose of each method and state transition.
      - Example structure:

      ```
        @riverpod
        class MyNotifier extends _$MyNotifier {
              Service get service => ref.read(ServiceProvider);

            @override
            FutureOr<AsyncValue<List<MyModel>>> build() async {

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

  2.  **Service Layer** (Business Logic):

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

  3.  **Repository Layer** (Data Access):

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

- **Folder placement**: the library is under vault feature folder as the following:

```
lib/
  features/
    vault/
      data/
        library/
      application/
        library/
```
