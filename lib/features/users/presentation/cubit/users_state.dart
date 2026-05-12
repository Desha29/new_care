import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../core/enums/user_role.dart';

abstract class UsersState extends Equatable {
  const UsersState();

  @override
  List<Object?> get props => [];
}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  final String searchQuery;
  final UserRole? roleFilter;

  const UsersLoaded({
    required this.users,
    this.searchQuery = '',
    this.roleFilter,
  });

  UsersLoaded copyWith({
    List<UserModel>? users,
    String? searchQuery,
    UserRole? roleFilter,
    bool clearRoleFilter = false,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
    );
  }

  List<UserModel> get filteredUsers {
    List<UserModel> result = users;

    // Filter by role
    if (roleFilter != null) {
      result = result.where((u) => u.role == roleFilter).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((u) =>
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.contains(q)
      ).toList();
    }

    return result;
  }

  @override
  List<Object?> get props => [users, searchQuery, roleFilter];
}

class UsersError extends UsersState {
  final String message;
  const UsersError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserOperationSuccess extends UsersState {
  final String message;
  const UserOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
