// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get goodDay => 'Olá';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String get allApplications => 'Todos os apps';

  @override
  String get tvApplications => 'Apps de TV';

  @override
  String get nonTvApplications => 'Apps que não são de TV';

  @override
  String get hiddenApplications => 'Apps ocultos';

  @override
  String get emptyCategory => 'Esta categoria está vazia.';

  @override
  String get addTo => 'Adicionar a…';

  @override
  String get addCategory => 'Adicionar uma categoria';

  @override
  String get renameCategory => 'Renomear a categoria';

  @override
  String get name => 'Nome';

  @override
  String get mustNotBeEmpty => 'Não pode ficar vazio';

  @override
  String get open => 'Abrir';

  @override
  String get move => 'Mover';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String removeFrom(String category) {
    return 'Remover de $category';
  }

  @override
  String get applicationInfo => 'Informações do app';

  @override
  String get uninstall => 'Desinstalar';

  @override
  String get nowPlaying => 'Tocando agora';

  @override
  String get resumePlayback => 'Retomar a reprodução';

  @override
  String get onAnotherDevice => 'Em outro dispositivo';

  @override
  String get notificationAccessNeeded => 'O acesso às notificações é necessário para mostrar o que está tocando.';

  @override
  String get notificationAccessGrantHint => 'Conceda-o em Configurações > Permissões e launcher padrão.';

  @override
  String get recentPlays => 'Reproduzidos recentemente';

  @override
  String get tvProgramsAccessNeeded =>
      'O acesso aos programas de TV é necessário para mostrar o que você pode continuar assistindo.';

  @override
  String get allow => 'Permitir';

  @override
  String get settings => 'Configurações';

  @override
  String get applications => 'Apps';

  @override
  String get categories => 'Categorias';

  @override
  String get accessesAndDefaultLauncher => 'Permissões e launcher padrão';

  @override
  String get use24HourTimeFormat => 'Formato de 24 horas';

  @override
  String get showAllApplications => 'Mostrar todos os apps';

  @override
  String get showRecentPlays => 'Mostrar os reproduzidos recentemente';

  @override
  String get deviceSettings => 'Configurações do dispositivo';

  @override
  String get about => 'Sobre o Waves Launcher TV';

  @override
  String get aboutDescription =>
      'O Waves Launcher TV é um launcher alternativo e de código aberto para Android TV, baseado no FLauncher e distribuído sob a licença GPLv3.\nCódigo-fonte disponível em ';

  @override
  String get sort => 'Ordem';

  @override
  String get alphabetical => 'Alfabética';

  @override
  String get manual => 'Manual';

  @override
  String get type => 'Tipo';

  @override
  String get row => 'Linha';

  @override
  String get grid => 'Grade';

  @override
  String get columnCount => 'Número de colunas';

  @override
  String get rowHeight => 'Altura da linha';

  @override
  String get delete => 'Excluir';

  @override
  String get defaultLauncher => 'Launcher padrão';

  @override
  String get defaultLauncherFeature => 'Aberto pelo botão Início';

  @override
  String get defaultLauncherHint =>
      'Se nenhuma janela foi aberta, é porque o launcher original do dispositivo não pode ser substituído aqui, é preciso desativá-lo com a ferramenta adb (veja o README do Waves Launcher TV).';

  @override
  String get tvPrograms => 'Programas de TV';

  @override
  String get tvProgramsHint =>
      'Se nenhuma janela foi aberta, permita “Ler todas as fontes de TV” em Configurações > Apps > Waves Launcher TV > Permissões.';

  @override
  String get notificationAccess => 'Acesso às notificações';

  @override
  String get notificationAccessHint =>
      'Ative o Waves Launcher TV em Configurações > Apps > Acesso especial a apps > Acesso a notificações.';

  @override
  String get nowPlayingFeature => 'Reprodução em andamento';

  @override
  String get accessibility => 'Acessibilidade';

  @override
  String get accessibilityFeature => 'Apps recentes ao pressionar Início duas vezes';

  @override
  String get accessibilityHint =>
      'Ative o Waves Launcher TV em Configurações > Preferências do dispositivo > Acessibilidade.';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get cancel => 'Cancelar';
}
