Below is a ready-to-add Markdown file (save it anywhere you keep project docs, e.g. `docs/usecase_flow.md`).  
It walks through the execution flow of a Clean-Architecture Use-Case in a Flutter app.

```markdown:docs/usecase_flow.md
# Clean Architecture – Use-Case Execution Flow (Flutter)

```
                                    +---------------+
     (1) User Action / UI Event --> |  Presentation |  (Widget / Bloc / Riverpod etc.)
                                    +-------+-------+
                                            |
                                            |  calls
                                            v
                               +------------+-------------+
                               |       Use Case           |  (Domain layer)
                               +------------+-------------+
                                            |
                         orchestrates        | interacts with
                                            v
                               +------------+-------------+
                               |     Repository (Abst.)   |  (Domain layer)
                               +------------+-------------+
                                            |
                             implemented by | (Data layer)
                                            v
                     +----------------------+-------------------+
                     |  Data Sources (API, Database, Cache …)  |
                     +----------------------+-------------------+
```

---

## 1. Presentation Layer

* **Who?** Widgets, Controllers, `Bloc`/`Cubit`, Riverpod `Provider`, etc.  
* **Role:** Captures user interaction (tap, scroll, lifecycle event) and **invokes a Use-Case** with the necessary **input parameters**.

```dart
final result = await getUserProfileUseCase(userId: '123');
```

---

## 2. Domain Layer – Use-Case

* **Pure business rule**: contains no Flutter, UI, or platform code.  
* **Single responsibility**: executes one specific application action.
* **Flow**
  1. Validates its input (`Params` object).
  2. Talks only to **abstract** repositories / services defined in the same layer.
  3. Returns an `Either<Failure, Entity>` (or `Result`, `Future<Entity>` etc.).

```dart
class GetUserProfileUseCase {
  final UserRepository _repo;
  GetUserProfileUseCase(this._repo);

  Future<Either<Failure, User>> call({required String userId}) async {
    if (userId.isEmpty) return left(Failure.invalidId());
    return _repo.fetchUser(userId);
  }
}
```

---

## 3. Domain Layer – Repository (Abstract)

* **Interface** that the Use-Case depends on.  
* **No implementation details** here.

```dart
abstract class UserRepository {
  Future<Either<Failure, User>> fetchUser(String id);
}
```

---

## 4. Data Layer – Repository Implementation

* **Implements** the abstract repository using one or more **Data Sources**.
* **Maps** raw models (DTOs) → **Domain Entities**.

```dart
class UserRepositoryImpl implements UserRepository {
  final RemoteDataSource remote;
  final LocalDataSource cache;

  @override
  Future<Either<Failure, User>> fetchUser(String id) async {
    try {
      final dto = await remote.getUser(id);
      cache.save(dto);                 // optional
      return right(dto.toDomain());
    } on ServerException catch (e) {
      return left(Failure.server(e.message));
    }
  }
}
```

---

## 5. Data Sources

1. **Remote** – REST, GraphQL, gRPC, Firebase …  
2. **Local** – SQLite, Hive, SharedPreferences, File storage …  
3. **Cache** – In-memory, disk …

Each source deals **only with its own technology**, has no business logic, and returns **Data Transfer Objects (DTOs)**.

---

## 6. Returning to Presentation

1. The **Use-Case** passes the `Either`/`Result` back to the caller.
2. The **Presentation layer** converts the `Entity` → `ViewModel` (if needed) and
   updates the UI (`setState`, `emit`, `ref.read`, etc.).
3. Errors are rendered via Snackbar, Dialog, error widget, etc.

---

## TL;DR Sequence

1. **UI** triggers → 2. **Use-Case** → 3. **Repository (abstract)** →  
4. **Repository Impl (data)** → 5. **Data Source** → (back up) →  
6. **Repository Impl** → 7. **Use-Case** → 8. **UI**

The separation ensures:

* **Testability** – Pure Dart tests for Use-Cases & Repositories.  
* **Maintainability** – Change one layer without affecting others.  
* **Scalability** – Add new data sources or presentation patterns easily.

---

Happy coding! 🎯