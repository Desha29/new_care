import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notifications/data_change_notifier.dart';
import '../../domain/repositories/users_repository.dart';
import '../../../auth/data/models/user_model.dart';
import 'users_state.dart';

class UsersCubit extends Cubit<UsersState> {
  final IUsersRepository _repository;

  UsersCubit({required IUsersRepository repository})
      : _repository = repository,
        super(UsersInitial());

  StreamSubscription? _usersSub;

  @override
  Future<void> close() {
    _usersSub?.cancel();
    return super.close();
  }

  Future<void> loadUsers({bool force = false}) async {
    if (!force && state is UsersLoaded) return;
    
    emit(UsersLoading());
    try {
      final users = await _repository.getAllUsers();
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError('خطأ في تحميل المستخدمين: ${e.toString()}'));
    }
  }

  void searchUsers(String query) {
    if (state is UsersLoaded) {
      final s = state as UsersLoaded;
      emit(s.copyWith(searchQuery: query));
    }
  }

  Future<void> toggleUserStatus(UserModel user) async {
    final newStatus = !user.isActive;
    final updatedUser = user.copyWith(
      isActive: newStatus,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateUser(updatedUser);
      emit(UserOperationSuccess('تم ${newStatus ? "تفعيل" : "تعطيل"} المستخدم ${user.name}'));
      DataChangeNotifier().notifyLocalDataChanged();
      loadUsers(force: true);
    } catch (e) {
      emit(UsersError('خطأ في تغيير حالة المستخدم: ${e.toString()}'));
    }
  }

  Future<void> deleteUser(String userId, String userName) async {
    try {
      await _repository.deleteUser(userId);
      emit(UserOperationSuccess('تم حذف المستخدم $userName بنجاح'));
      DataChangeNotifier().notifyLocalDataChanged();
      loadUsers(force: true);
    } catch (e) {
      emit(UsersError('خطأ في حذف المستخدم: ${e.toString()}'));
    }
  }

  void resetState() {
    if (state is UserOperationSuccess || state is UsersError) {
      loadUsers();
    }
  }
}
