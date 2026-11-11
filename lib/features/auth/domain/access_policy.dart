import 'entities/user_entity.dart';

const _transactionCreateRoles = {'Owner', 'Admin', 'Kasir', 'KepalaCabang'};
const _transactionReadRoles = {
  'Owner',
  'Admin',
  'Kasir',
  'Keuangan',
  'KepalaCabang',
};

bool canCreateTransactions(UserEntity user) =>
    user.permissions.contains('transaction.create') ||
    _transactionCreateRoles.contains(user.role);

bool canReadTransactions(UserEntity user) =>
    _transactionReadRoles.contains(user.role);

bool canManageStock(UserEntity user) =>
    user.permissions.contains('stock.manage') ||
    {'Owner', 'Admin', 'KepalaCabang', 'Gudang'}.contains(user.role);
