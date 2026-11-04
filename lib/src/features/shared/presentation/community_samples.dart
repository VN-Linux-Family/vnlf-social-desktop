import '../../../design_system/design_system.dart';

/// Invented identities for the local community experience; no network avatars.
const communityMembers = [
  AuthorData(
    id: 'user-synth-1',
    username: 'hoangnam',
    displayName: 'Hoàng Nam',
    style: AuthorStyleData(distroBadge: DistroBadgeType.arch),
  ),
  AuthorData(
    id: 'user-synth-2',
    username: 'minhtri',
    displayName: 'Minh Trí',
    style: AuthorStyleData(distroBadge: DistroBadgeType.cachyos),
  ),
  AuthorData(
    id: 'user-synth-3',
    username: 'linhdan',
    displayName: 'Linh Đan',
    style: AuthorStyleData(distroBadge: DistroBadgeType.debian),
  ),
];

const communityGuest = AuthorData(
  id: 'local-guest',
  username: 'ban',
  displayName: 'Bạn',
  style: AuthorStyleData(distroBadge: DistroBadgeType.fedora),
);
