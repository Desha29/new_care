import 'package:equatable/equatable.dart';
import '../../../auth/data/models/user_model.dart';

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

  const UsersLoaded({
    required this.users,
    this.searchQuery = '',
  });

  UsersLoaded copyWith({
    List<UserModel>? users,
    String? searchQuery,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<UserModel> get filteredUsers {
    if (searchQuery.isEmpty) return users;
    final q = searchQuery.toLowerCase();
    return users.where((u) =>
      u.name.toLowerCase().contains(q) ||
      u.email.toLowerCase().contains(q) ||
      u.phone.contains(q)
    ).toList();
  }

  @override
  List<Object?> get props => [users, searchQuery];
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
