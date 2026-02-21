/// Helper para manejar la distinción de género en los roles
/// SIN MODIFICAR la clase RoleDefinition existente.

class RoleGenderHelper {
  static String getRoleName(String roleKey, String? gender) {
    if (gender == null) return _getDefaultName(roleKey);
    final g = gender.toLowerCase();
    if (g != 'female' && g != 'femenino') {
      // Retorna el nombre masculino por defecto
      return _getDefaultName(roleKey);
    }

    // Lógica para nombres Femeninos
    switch (roleKey) {
      case 'pro-boxer':
        return 'Boxeadora Profesional';
      case 'amateur-boxer':
        return 'Boxeadora Amateur';
      case 'cadet':
        return 'Cadete (F)'; // O el término que prefieras
      case 'recreational':
        return 'Boxeo Recreativo'; // Neutro
      case 'retired-boxer':
        return 'Boxeadora Retirada';
      case 'legend-boxer':
        return 'Leyenda (F)';
      case 'coach':
        return 'Entrenadora';
      case 'promoter':
        return 'Promotora';
      case 'judge':
        return 'Jueza';
      case 'medic':
        return 'Médica de Ringside';
      case 'nutritionist':
        return 'Nutricionista';
      case 'psychologist':
        return 'Psicóloga Deportiva';
      case 'journalist':
        return 'Periodista';
      case 'cutman':
        return 'Cutwoman'; // Término técnico
      case 'gym-owner':
        return 'Dueña de Gimnasio';
      default:
        return _getDefaultName(roleKey);
    }
  }

  static String _getDefaultName(String roleKey) {
    // Mapeo manual para no depender de importar todo app_roles y causar dependencias circulares
    switch (roleKey) {
      case 'pro-boxer':
        return 'Boxeador Profesional';
      case 'amateur-boxer':
        return 'Boxeador Amateur';
      case 'cadet':
        return 'Cadete';
      case 'recreational':
        return 'Recreativo';
      case 'retired-boxer':
        return 'Boxeador Retirado';
      case 'legend-boxer':
        return 'Leyenda';
      case 'coach':
        return 'Entrenador';
      case 'promoter':
        return 'Promotor';
      case 'judge':
        return 'Juez';
      case 'medic':
        return 'Médico';
      case 'nutritionist':
        return 'Nutricionista';
      case 'psychologist':
        return 'Psicólogo';
      case 'journalist':
        return 'Periodista';
      case 'cutman':
        return 'Cutman';
      case 'gym-owner':
        return 'Dueño de Gimnasio';
      default:
        return 'Usuario';
    }
  }
}
