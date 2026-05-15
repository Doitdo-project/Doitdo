import 'package:json_annotation/json_annotation.dart';

part 'wallet_balance_dto.g.dart';

/// `GET /api/users/me/balance` 응답의 `data` 필드.
///
/// 스웨거 `WalletBalanceResp` 와 1:1 매핑.
/// ```json
/// { "balance": 1240 }
/// ```
@JsonSerializable()
class WalletBalanceDto {
  const WalletBalanceDto({required this.balance});

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceDtoFromJson(json);

  final int balance;

  Map<String, dynamic> toJson() => _$WalletBalanceDtoToJson(this);
}